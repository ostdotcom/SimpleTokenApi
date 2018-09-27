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

    # do not process if kyc was resubmitted
    return if @user_extended_detail_id != @user_kyc_detail.user_extended_detail_id

    block_kyc_submit_job_hard_check

    #  todo: "KYCaas-Changes"
    # create_email_service_api_call_hook

    decrypt_kyc_salt

    check_duplicate_kyc_documents

    call_cynopsis_api

    add_kyc_comparison_details

    UserActivityLogJob.new().perform({
                                         user_id: @user_id,
                                         action: @action,
                                         action_timestamp: @action_timestamp
                                     })
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
    @user_extended_detail_id = params[:user_extended_detail_id]
    @action = params[:action]
    @action_timestamp = params[:action_timestamp]

    @user = User.find(@user_id)
    @user_extended_detail = UserExtendedDetail.find(@user_extended_detail_id)
    @user_kyc_detail = UserKycDetail.get_from_memcache(@user_id)

    Rails.logger.info("-- init_params @user_extended_detail: #{@user_extended_detail.id}")

    @cynopsis_status = GlobalConstant::UserKycDetail.unprocessed_cynopsis_status

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

    if (@user_kyc_detail.kyc_approved? || @user_kyc_detail.kyc_denied?)
      fail "KYC is already approved for user id: #{@user_id}."
    end

    if @user.id != @user_extended_detail.user_id
      fail "KYC doesn't belong to user id: #{@user_id}."
    end

    Rails.logger.info('-- block_kyc_submit_job_hard_check done')
  end



  #  todo: "KYCaas-Changes"
  # Find POS bonus for percentage
  #
  # * Author: Aman
  # * Date: 12/10/2017
  # * Reviewed By: Sunil
  #
  # def get_pos_bonus_percentage
  #   PosBonusEmail.where(email: @user.email).first.try(:bonus_percentage)
  # end

  # Find Alternate Token Id for bonus
  #
  # * Author: Aman
  # * Date: 12/10/2017
  # * Reviewed By: Sunil
  #
  #  todo: "KYCaas-Changes"
  # def get_alternate_token_id_for_bonus
  #   AlternateTokenBonusEmail.where(email: @user.email).first.try(:alternate_token_id)
  # end

  # Create Hook to sync data in Email Service
  #
  # * Author: Kedar, Puneet
  # * Date: 12/10/2017
  # * Reviewed By: Sunil
  #  todo: "KYCaas-Changes"
  # def create_email_service_api_call_hook
  #   return if @is_re_submit
  #
  #   Rails.logger.info('-- create_email_service_api_call_hook')
  #
  #   Email::HookCreator::AddContact.new(
  #       email: @user.email,
  #       custom_attributes: {
  #         GlobalConstant::PepoCampaigns.token_sale_registered_attribute => GlobalConstant::PepoCampaigns.token_sale_registered_value,
  #         GlobalConstant::PepoCampaigns.token_sale_kyc_confirmed_attribute => GlobalConstant::PepoCampaigns.token_sale_kyc_confirmed_value,
  #         GlobalConstant::PepoCampaigns.token_sale_phase_attribute => @user_kyc_detail.token_sale_participation_phase
  #       }
  #   ).perform
  #
  # end

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
  #
  def check_duplicate_kyc_documents
    Rails.logger.info('-- check_duplicate_kyc_documents')
    r = AdminManagement::Kyc::CheckDuplicates.new(user_id: @user_id).perform
    return r unless r.success?

    @user_kyc_detail.reload
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

    if !r.success? # cynopsis status will turn failed
      @cynopsis_status = GlobalConstant::UserKycDetail.failed_cynopsis_status
      save_cynopsis_status
      log_to_user_activity(r)
      return
    end

    response_hash = ((r.data || {})[:response] || {})
    @cynopsis_status = GlobalConstant::UserKycDetail.get_cynopsis_status(response_hash['approval_status'].to_s)
    @user_kyc_detail.cynopsis_user_id = get_cynopsis_user_id
    save_cynopsis_status
    # upload_documents
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
    Cynopsis::Customer.new(client_id: @user.client_id).create(cynopsis_params)
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
    Cynopsis::Customer.new(client_id: @user.client_id).update(cynopsis_params, true)
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
        date_of_birth: Time.zone.strptime(date_of_birth_d, "%Y-%m-%d").strftime("%d/%m/%Y"),
        identification_type: 'PASSPORT',
        identification_number: document_id_number_d,
        nationality: nationality_d.upcase
    }

  end

  # Save cynopsis response status
  #
  # * Author: Kedar, Puneet
  # * Date: 12/10/2017
  # * Reviewed By: Sunil
  #
  def save_cynopsis_status
    Rails.logger.info('-- save_cynopsis_status')
    @user_kyc_detail.cynopsis_status = @cynopsis_status
    @user_kyc_detail.save! if @user_kyc_detail.changed?
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
    upload_document(document_id_file_path_d, 'PASSPORT')
    upload_document(selfie_file_path_d, 'OTHERS', 'selfie')
    residence_proof_file = residence_proof_file_path_d
    upload_document(residence_proof_file, 'OTHERS', 'residence_proof') if residence_proof_file.present?
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

    file_name = s3_path.split('/').last
    local_file_path = "#{Rails.root}/tmp/#{file_name}"

    s3_obj = Aws::S3Manager.new(@run_purpose, @run_role)
    s3_obj.get(local_file_path, s3_path, GlobalConstant::Aws::Common.kyc_bucket)

    upload_params = {
        rfrID: get_cynopsis_user_id,
        local_file_path: local_file_path,
        document_type: document_type
    }

    upload_params[:please_mention] = desc if document_type == 'OTHERS'

    r = Cynopsis::Document.new(client_id: @user.client_id).upload(upload_params)

    if !r.success?
      log_to_user_activity(r)
    end

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
  # Rails.env[0..1] - (de/sa/st/pr)
  #
  def get_cynopsis_user_id
    @get_cynopsis_user_id ||= @user_kyc_detail.cynopsis_user_id.present? ? @user_kyc_detail.cynopsis_user_id.to_s :
                                  UserKycDetail.get_cynopsis_user_id(@user_id)
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

  # Get decrypted document_id number
  #
  # * Author: Kedar, Puneet
  # * Date: 12/10/2017
  # * Reviewed By: Sunil
  #
  def document_id_number_d
    local_cipher_obj.decrypt(@user_extended_detail.document_id_number).data[:plaintext]
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

  # Get decrypted document id file path
  #
  # * Author: Kedar, Puneet
  # * Date: 12/10/2017
  # * Reviewed By: Sunil
  #
  def document_id_file_path_d
    local_cipher_obj.decrypt(@user_extended_detail.document_id_file_path).data[:plaintext]
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

  # local cipher obj
  #
  # * Author: Kedar, Puneet
  # * Date: 12/10/2017
  # * Reviewed By: Sunil
  #
  def local_cipher_obj
    @local_cipher_obj ||= LocalCipher.new(@kyc_salt_d)
  end

  # Log to user activity
  #
  # * Author: Abhay
  # * Date: 28/10/2017
  # * Reviewed By: Sunil
  #
  def log_to_user_activity(response)
    UserActivityLogJob.new().perform({
                                         user_id: @user_kyc_detail.user_id,
                                         action: GlobalConstant::UserActivityLog.cynopsis_api_error,
                                         action_timestamp: Time.now.to_i,
                                         extra_data: {
                                             response: response.to_json
                                         }
                                     })
  end

  # Make entry to user kyc comparison details for image processing and comparisons
  #
  # * Author: Pankaj
  # * Date: 02/07/2018
  # * Reviewed By:
  #
  def add_kyc_comparison_details
    UserKycComparisonDetail.create!(user_extended_detail_id: @user_extended_detail.id, client_id: @user_kyc_detail.client_id,
                                    image_processing_status: GlobalConstant::ImageProcessing.unprocessed_image_process_status)
  end

end

