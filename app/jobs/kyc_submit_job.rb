class KycSubmitJob < ApplicationJob

  queue_as GlobalConstant::Sidekiq.queue_name :default_high_priority_queue

  # Perform
  #
  # * Author: Kedar, Puneet
  # * Date: 12/10/2017
  # * Reviewed By: Sunil
  #
  # @param [Hash] params
  #
  def perform(params)
    init_params(params)

    block_kyc_submit_job_hard_check

    find_or_init_user_kyc_detail

    create_email_service_api_call_hook

    decrypt_kyc_salt

    check_duplicate_kyc_documents

    call_cynopsis_api
  end

  private

  # Init params
  #
  # * Author: Kedar, Puneet
  # * Date: 12/10/2017
  # * Reviewed By: Sunil
  #
  # @param [Hash] params
  #
  def init_params(params)
    Rails.logger.info("-- init_params params: #{params.inspect}")

    @user_id = params[:user_id]

    @user = User.find(@user_id)
    @user_extended_detail = UserExtendedDetail.where(user_id: @user_id).last
    Rails.logger.info("-- init_params @user_extended_detail: #{@user_extended_detail.id}")

    @cynopsis_status = GlobalConstant::UserKycDetail.un_processed_cynopsis_status
    @is_duplicate = false

    @run_role = 'admin'
    @run_purpose = 'kyc'

    @kyc_salt_e = @user_extended_detail.kyc_salt
    @kyc_salt_d = nil
  end

  # Block kyc hard check
  #
  # * Author: Kedar, Puneet
  # * Date: 12/10/2017
  # * Reviewed By: Sunil
  #
  def block_kyc_submit_job_hard_check
    # Double optin is required
    if !@user.send("#{GlobalConstant::User.token_sale_double_optin_done_property}?")
      fail "Double optin not yet done by user id: #{@user_id}."
    end

    # Check if user KYC is already approved
    user_kyc_detail = UserKycDetail.where(user_id: @user_id).first
    if user_kyc_detail.present? && user_kyc_detail.kyc_approved?
      fail "KYC is already approved for user id: #{@user_id}."
    end

    if @user.id != @user_extended_detail.user_id
      fail "KYC doesn't belong to user id: #{@user_id}."
    end

    Rails.logger.info('-- block_kyc_submit_job_hard_check done')
  end

  # Find or init user kyc detail
  #
  # * Author: Kedar
  # * Date: 13/10/2017
  # * Reviewed By: Sunil
  #
  # Sets @user_kyc_detail, @is_re_submit
  #
  def find_or_init_user_kyc_detail
    @user_kyc_detail = UserKycDetail.find_or_initialize_by(user_id: @user_id)

    @is_re_submit = @user_kyc_detail.new_record? ? false : true

    # don't override the data if user kyc details id is same
    return if @user_kyc_detail.user_extended_detail_id.to_i == @user_extended_detail.id

    Rails.logger.info('-- find_or_init_user_kyc_detail')

    # Update records
    if @user_kyc_detail.new_record?
      @user_kyc_detail.kyc_confirmed_at = Time.now.to_i
      @user_kyc_detail.token_sale_participation_phase = GlobalConstant::TokenSale.token_sale_phase_for(Time.now)
    end
    @user_kyc_detail.user_extended_detail_id = @user_extended_detail.id
    @user_kyc_detail.is_re_submitted = @is_re_submit.to_i
    @user_kyc_detail.is_duplicate = @is_duplicate.to_i
    @user_kyc_detail.cynopsis_status = GlobalConstant::UserKycDetail.un_processed_cynopsis_status
    @user_kyc_detail.admin_status = GlobalConstant::UserKycDetail.un_processed_admin_status
    @user_kyc_detail.last_acted_by = nil
    @user_kyc_detail.save!
  end

  # Create Hook to sync data in Email Service
  #
  # * Author: Kedar, Puneet
  # * Date: 12/10/2017
  # * Reviewed By: Sunil
  #
  def create_email_service_api_call_hook
    return if @is_re_submit

    Rails.logger.info('-- create_email_service_api_call_hook')

    Email::HookCreator::AddContact.new(
      email: @user.email,
      token_sale_phase: @user_kyc_detail.token_sale_participation_phase
    ).perform
  end

  # Decrypt kyc salt
  #
  # * Author: Kedar, Puneet
  # * Date: 12/10/2017
  # * Reviewed By: Sunil
  #
  # Sets @kyc_salt_d
  #
  def decrypt_kyc_salt
    Rails.logger.info('-- decrypt_kyc_salt')

    r = Aws::Kms.new(@run_purpose, @run_role).decrypt(@kyc_salt_e)
    fail 'decryption of kyc salt failed.' unless r.success?

    @kyc_salt_d = r.data[:plaintext]
  end

  ########################## Duplicate KYC handling ##########################

  # Check for duplicate KYC details
  #
  # * Author: Kedar, Puneet
  # * Date: 12/10/2017
  # * Reviewed By: Sunil
  #
  # Sets @is_duplicate
  #
  def check_duplicate_kyc_documents
    # TODO implement the duplication checks.
    @is_duplicate = false
    save_duplicate_kyc_status
  end

  # Save duplicate status
  #
  # * Author: Kedar, Puneet
  # * Date: 12/10/2017
  # * Reviewed By: Sunil
  #
  def save_duplicate_kyc_status
    Rails.logger.info('-- save_duplicate_kyc_status')
    @user_kyc_detail.is_duplicate = @is_duplicate.to_i
    @user_kyc_detail.save!
  end

  ########################## Cynopsis handling ##########################

  # Cynopsis
  #
  # * Author: Kedar, Puneet
  # * Date: 12/10/2017
  # * Reviewed By: Sunil
  #
  def call_cynopsis_api
    r = @user_kyc_detail.cynopsis_user_id.blank? ? create_cynopsis_case : update_cynopsis_case
    Rails.logger.info("-- call_cynopsis_api r: #{r.inspect}")
    return unless r.success? # cynopsis status will remain unprocessed

    response_hash = ((r.data || {})[:response] || {})
    set_cynopsis_status(response_hash)
    save_cynopsis_status
    upload_documents
  end

  # Create user in cynopsis
  #
  # * Author: Kedar, Puneet
  # * Date: 12/10/2017
  # * Reviewed By: Sunil
  #
  # @return [Result::Base]
  #
  def create_cynopsis_case
    Cynopsis::Customer.new().create(cynopsis_params)
  end

  # Update user in cynopsis
  #
  # * Author: Kedar, Puneet
  # * Date: 12/10/2017
  # * Reviewed By: Sunil
  #
  # @return [Result::Base]
  #
  def update_cynopsis_case
    Cynopsis::Customer.new().update(cynopsis_params, true)
  end

  # Create cynopsis params
  #
  # * Author: Kedar, Puneet
  # * Date: 12/10/2017
  # * Reviewed By: Sunil
  #
  def cynopsis_params
    {
        rfrID: get_cynopsis_user_id,
        first_name: @user_extended_detail.first_name,
        last_name: @user_extended_detail.last_name,
        country_of_residence: country_of_residence_d.upcase,
        date_of_birth: Date.parse(date_of_birth_d).strftime("%d/%m/%Y"),
        identification_type: 'PASSPORT',
        identification_number: passport_number_d,
        nationality: nationality_d.upcase,
        emails: [@user.email],
        addresses: address_d
    }
  end

  # Set cynopsis response status
  #
  # * Author: Kedar, Puneet
  # * Date: 12/10/2017
  # * Reviewed By: Sunil
  #
  # Sets @cynopsis_status
  #
  def set_cynopsis_status(response_hash)
    approval_status = response_hash['approval_status'].to_s

    if approval_status == 'PENDING'
      @cynopsis_status = GlobalConstant::UserKycDetail.pending_cynopsis_status
    elsif approval_status == 'CLEARED'
      @cynopsis_status = GlobalConstant::UserKycDetail.cleared_cynopsis_status
    elsif approval_status == 'ACCEPTED'
      @cynopsis_status = GlobalConstant::UserKycDetail.approved_cynopsis_status
    elsif approval_status == 'REJECTED'
      @cynopsis_status = GlobalConstant::UserKycDetail.rejected_cynopsis_status
    else
      @cynopsis_status = GlobalConstant::UserKycDetail.un_processed_cynopsis_status
    end
  end

  # Save cynopsis response status
  #
  # * Author: Kedar, Puneet
  # * Date: 12/10/2017
  # * Reviewed By: Sunil
  #
  def save_cynopsis_status
    Rails.logger.info('-- save_cynopsis_status')
    @user_kyc_detail.cynopsis_user_id = get_cynopsis_user_id
    @user_kyc_detail.cynopsis_status = @cynopsis_status
    @user_kyc_detail.save!
  end

  # Upload documents to cynopsis
  #
  # * Author: Kedar, Puneet
  # * Date: 12/10/2017
  # * Reviewed By: Sunil
  #
  def upload_documents
    return unless document_upload_needed?
    Rails.logger.info("-- upload_documents")
    upload_document(passport_file_path_d, 'PASSPORT')
    upload_document(selfie_file_path_d, 'OTHERS', 'selfie')
    upload_document(residence_proof_file_path_d, 'OTHERS', 'residence_proof') if residence_proof_file_path_d.present?
  end

  # Check if document upload is required or not
  #
  # * Author: Kedar, Puneet
  # * Date: 12/10/2017
  # * Reviewed By: Sunil
  #
  # @return [Boolean]
  #
  def document_upload_needed?
    @cynopsis_status == GlobalConstant::UserKycDetail.pending_cynopsis_status
  end

  #  Upload documents call
  #
  # * Author: Kedar, Puneet
  # * Date: 12/10/2017
  # * Reviewed By: Sunil
  #
  def upload_document(s3_path, document_type, desc = nil)
    Rails.logger.info("-- upload_document: #{document_type} start")

    url = Aws::S3Manager.new(@run_purpose, @run_role).
        get_signed_url_for(GlobalConstant::Aws::Common.kyc_bucket, s3_path)

    file_name = passport_file_path_d.split('/').last

    local_file_path = "#{Rails.root}/tmp/#{file_name}"

    system("wget -O #{local_file_path} '#{url}'")

    upload_params = {
        rfrID: get_cynopsis_user_id,
        local_file_path: local_file_path,
        document_type: document_type
    }

    upload_params[:please_mention] = desc if document_type == 'OTHERS'

    Cynopsis::Document.new().upload(upload_params)

    File.delete(local_file_path)
    Rails.logger.info("-- upload_document: #{document_type} done")
  end

  # Get cynopsis rfrID
  #
  # * Author: Kedar, Puneet
  # * Date: 12/10/2017
  # * Reviewed By: Sunil
  #
  # ts - (token sale)
  # Rails.env[0] - (d/s/p)
  #
  def get_cynopsis_user_id
    "ts_#{Rails.env[0]}_#{@user_id}"
  end

  # Get decrypted country
  #
  # * Author: Kedar, Puneet
  # * Date: 12/10/2017
  # * Reviewed By: Sunil
  #
  def country_of_residence_d
    local_cipher_obj.decrypt(@user_extended_detail.country).data[:plaintext]
  end

  # Get decrypted birth date
  #
  # * Author: Kedar, Puneet
  # * Date: 12/10/2017
  # * Reviewed By: Sunil
  #
  def date_of_birth_d
    local_cipher_obj.decrypt(@user_extended_detail.birthdate).data[:plaintext]
  end

  # Get decrypted passport number
  #
  # * Author: Kedar, Puneet
  # * Date: 12/10/2017
  # * Reviewed By: Sunil
  #
  def passport_number_d
    local_cipher_obj.decrypt(@user_extended_detail.passport_number).data[:plaintext]
  end

  # Get decrypted nationality
  #
  # * Author: Kedar, Puneet
  # * Date: 12/10/2017
  # * Reviewed By: Sunil
  #
  def nationality_d
    local_cipher_obj.decrypt(@user_extended_detail.nationality).data[:plaintext]
  end

  # Get decrypted passport file path
  #
  # * Author: Kedar, Puneet
  # * Date: 12/10/2017
  # * Reviewed By: Sunil
  #
  def passport_file_path_d
    local_cipher_obj.decrypt(@user_extended_detail.passport_file_path).data[:plaintext]
  end

  # Get decrypted selfie file path
  #
  # * Author: Kedar, Puneet
  # * Date: 12/10/2017
  # * Reviewed By: Sunil
  #
  def selfie_file_path_d
    local_cipher_obj.decrypt(@user_extended_detail.selfie_file_path).data[:plaintext]
  end

  # Get decrypted residence proof file path
  #
  # * Author: Kedar, Puneet
  # * Date: 12/10/2017
  # * Reviewed By: Sunil
  #
  def residence_proof_file_path_d
    @user_extended_detail.residence_proof_file_path.present? ?
      local_cipher_obj.decrypt(@user_extended_detail.residence_proof_file_path).data[:plaintext] :
      ''
  end

  # Get decrypted address
  #
  # * Author: Kedar, Puneet
  # * Date: 12/10/2017
  # * Reviewed By: Sunil
  #
  def address_d
    [street_address_d, city_d, state_d, country_of_residence_d, postal_code_d].join(', ')
  end

  # Get decrypted street address
  #
  # * Author: Kedar, Puneet
  # * Date: 12/10/2017
  # * Reviewed By: Sunil
  #
  def street_address_d
    local_cipher_obj.decrypt(@user_extended_detail.street_address).data[:plaintext]
  end

  # Get decrypted city
  #
  # * Author: Kedar, Puneet
  # * Date: 12/10/2017
  # * Reviewed By: Sunil
  #
  def city_d
    local_cipher_obj.decrypt(@user_extended_detail.city).data[:plaintext]
  end

  # Get decrypted state
  #
  # * Author: Kedar, Puneet
  # * Date: 12/10/2017
  # * Reviewed By: Sunil
  #
  def state_d
    local_cipher_obj.decrypt(@user_extended_detail.state).data[:plaintext]
  end

  # Get decrypted postal code
  #
  # * Author: Kedar, Puneet
  # * Date: 12/10/2017
  # * Reviewed By: Sunil
  #
  def postal_code_d
    local_cipher_obj.decrypt(@user_extended_detail.postal_code).data[:plaintext]
  end

  # local cipher obj
  #
  # * Author: Kedar, Puneet
  # * Date: 12/10/2017
  # * Reviewed By: Sunil
  #
  def local_cipher_obj
    @local_cipher_obj ||= LocalCipher.new(@kyc_salt_d)
  end

end

