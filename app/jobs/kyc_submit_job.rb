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

    # Untill the user Does Double Opt in do nothing here
    return unless @user.send("#{GlobalConstant::User.token_sale_double_optin_done_property}?")

    find_or_init_user_kyc_detail

    create_email_service_api_call_hook

    associate_ued_with_user

    decrypt_kyc_salt

    call_cynopsis_api

    set_duplicate_log

    save_user_kyc_detail

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
    @user_id = params[:user_id]
    @is_re_submit = params[:is_re_submit]

    @user = User.find(@user_id)
    @user_extended_detail = UserExtendedDetail.where(user_id: @user_id).last
    @cynopsis_status = GlobalConstant::UserKycDetail.un_processed_cynopsis_status
    @is_duplicate = false

    @run_role = 'admin'
    @run_purpose = 'kyc'

    @kyc_salt_e = @user_extended_detail.kyc_salt
    @kyc_salt_d = nil
  end

  # Find or init user kyc detail
  #
  # * Author: Kedar
  # * Date: 13/10/2017
  # * Reviewed By:
  #
  # Sets @user_kyc_detail
  #
  def find_or_init_user_kyc_detail
    @user_kyc_detail = UserKycDetail.find_or_initialize_by(user_id: @user_id)
    @user_kyc_detail.kyc_confirmed_at ||= Time.now.to_i
    @user_kyc_detail.is_re_submitted = @is_re_submit.to_i
    @user_kyc_detail.is_duplicate = @is_duplicate.to_i
    @user_kyc_detail.last_acted_by = nil
    @user_kyc_detail.cynopsis_status = GlobalConstant::UserKycDetail.un_processed_cynopsis_status
    @user_kyc_detail.admin_status = GlobalConstant::UserKycDetail.un_processed_admin_status
    @user_kyc_detail.user_extended_detail_id = @user_extended_detail.id
    @user_kyc_detail.token_sale_participation_phase ||= GlobalConstant::TokenSale.token_sale_phase_for(@user_kyc_detail.kyc_confirmed_at)
  end

  # Create Hook to sync data in Email Service
  #
  # * Author: Kedar, Puneet
  # * Date: 12/10/2017
  # * Reviewed By: Sunil
  #
  def create_email_service_api_call_hook

    return if @is_re_submit

    Email::HookCreator::AddContact.new(
      email: @user.email,
      token_sale_phase: GlobalConstant::TokenSale.token_sale_phase_for
    ).perform

  end

  #
  # * Author: Kedar, Puneet
  # * Date: 12/10/2017
  # * Reviewed By: Sunil
  #
  # Sets @user_extended_detail
  #
  def associate_ued_with_user
    @user.user_extended_detail_id = @user_extended_detail.id
    @user.save!
  end

  #
  # * Author: Kedar, Puneet
  # * Date: 12/10/2017
  # * Reviewed By: Sunil
  #
  #
  # @params [String] rfrID (mandatory) - Customer reference id
  # @params [String] first_name (mandatory) - Customer first name
  # @params [String] last_name (mandatory) - Customer last name
  # @params [String] country_of_residence (mandatory) - Customer residence country
  # @params [String] date_of_birth (mandatory) - Customer date of birth (format: "%d/%m/%Y")
  # @params [String] identification_type (mandatory) - Customer identification type
  # @params [String] identification_number (mandatory) - Customer identification number
  # @params [String] nationality (mandatory) - Customer nationality
  # @params [Array] emails (mandatory) - Customer email addresses
  # @params [String] addresses (mandatory) - Customer address separated by comma
  #
  def call_cynopsis_api

    r = @is_re_submit ?
      update_cynopsis_case :
      create_cynopsis_case

    set_cynopsis_status(r)

    upload_documents

  end

  #
  # * Author: Kedar, Puneet
  # * Date: 12/10/2017
  # * Reviewed By: Sunil
  #
  # Sets @is_duplicate
  #
  def set_duplicate_log
    # TODO implement the duplication checks.
    @is_duplicate = false
  end

  #
  # * Author: Kedar, Puneet
  # * Date: 12/10/2017
  # * Reviewed By: Sunil
  #
  def save_user_kyc_detail
    @user_kyc_detail.cynopsis_status = @cynopsis_status
    @user_kyc_detail.is_duplicate = @is_duplicate.to_i
    @user_kyc_detail.save!
  end

  #
  # * Author: Kedar, Puneet
  # * Date: 12/10/2017
  # * Reviewed By: Sunil
  #
  def upload_documents
    return unless document_upload_needed?
    upload_document(passport_file_path_d, 'PASSPORT')
    upload_document(selfie_file_path_d, 'OTHERS', 'selfie')
    upload_document(residence_proof_file_path_d, 'OTHERS', 'residence_proof') if residence_proof_file_path_d.present?
  end

  #
  # * Author: Kedar, Puneet
  # * Date: 12/10/2017
  # * Reviewed By:
  #
  # @return [Boolean]
  #
  def document_upload_needed?
    # {
    #   :response => {
    #       "status" => "COMPLETED",
    #       "own_list_search"=>[],
    #       "approval_status"=>"CLEARED",
    #       "control_list_search" => {
    #             "is_hit"=>false,
    #             "timeStamp"=>"2017-10-13 10:24:39.973199+00:00",
    #             "scanResult" => {},
    #             "indivscanID"=>nil,
    #             "error"=>nil
    #             },
    #       "rfrID"=>"test13_1",
    #       "internet_search"=>nil,
    #       "screening_database_search"=>[]
    #       }
    # }


    # {:response=>
    #    {"status"=>"PENDING-L2",
    #     "approval_status"=>"PENDING",
    #     "rfrID"=>"test13_2",
    #     "screening_database_search"=>
    #       [{"surname"=>"bin Laden.", ...
    #         },
    #     "check_status_url"=>
    #       "https://d1.cynopsis-solutions.com/artemis_simpletoken/default/check_status.json/?customer=19",
    #     "internet_search"=>nil}}

    @cynopsis_status == GlobalConstant::UserKycDetail.pending_cynopsis_status
  end

  #
  # * Author: Kedar, Puneet
  # * Date: 12/10/2017
  # * Reviewed By: Sunil
  #
  def upload_document(s3_path, document_type, desc = nil)

    url = Aws::S3Manager.new('kyc', 'admin').
      get_signed_url_for(GlobalConstant::Aws::Common.kyc_bucket, s3_path)

    file_name = passport_file_path_d.split('/').last

    local_file_path = "#{Rails.root}/tmp/#{file_name}"

    system("wget -O #{local_file_path} '#{url}'")

    upload_params = {
      rfrID: cynopsis_params[:rfrID],
      local_file_path: local_file_path,
      document_type: document_type
    }

    upload_params[:please_mention] = desc if document_type == 'OTHERS'

    Cynopsis::Document.new().upload(upload_params)

    File.delete(local_file_path)

  end

  #
  # * Author: Kedar, Puneet
  # * Date: 12/10/2017
  # * Reviewed By: Sunil
  #
  def create_cynopsis_case
    Cynopsis::Customer.new().create(cynopsis_params)
  end

  #
  # * Author: Kedar, Puneet
  # * Date: 12/10/2017
  # * Reviewed By: Sunil
  #
  def update_cynopsis_case
    Cynopsis::Customer.new().update(cynopsis_params)
  end

  #
  # * Author: Kedar, Puneet
  # * Date: 12/10/2017
  # * Reviewed By: Sunil
  #
  def set_cynopsis_status(r)
    return unless r.success? # cynopsis status will remain unprocessed

    response_hash = ((r.data || {})[:response] || {})

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

  #
  # * Author: Kedar, Puneet
  # * Date: 12/10/2017
  # * Reviewed By: Sunil
  #
  def cynopsis_params
    {
      rfrID: "ts2_#{@user_id}",
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

  # Decrypt kyc salt
  #
  # * Author: Kedar, Puneet
  # * Date: 12/10/2017
  # * Reviewed By: Sunil
  #
  # Sets @kyc_salt_d
  #
  def decrypt_kyc_salt

    r = Aws::Kms.new(@run_purpose, @run_role).decrypt(@kyc_salt_e)
    fail 'decryption of kyc salt failed.' unless r.success?

    @kyc_salt_d = r.data[:plaintext]

  end

  #
  # * Author: Kedar, Puneet
  # * Date: 12/10/2017
  # * Reviewed By: Sunil
  #
  def country_of_residence_d
    local_cipher_obj.decrypt(@user_extended_detail.country).data[:plaintext]
  end

  #
  # * Author: Kedar, Puneet
  # * Date: 12/10/2017
  # * Reviewed By: Sunil
  #
  def date_of_birth_d
    local_cipher_obj.decrypt(@user_extended_detail.birthdate).data[:plaintext]
  end

  #
  # * Author: Kedar, Puneet
  # * Date: 12/10/2017
  # * Reviewed By: Sunil
  #
  def passport_number_d
    local_cipher_obj.decrypt(@user_extended_detail.passport_number).data[:plaintext]
  end

  #
  # * Author: Kedar, Puneet
  # * Date: 12/10/2017
  # * Reviewed By: Sunil
  #
  def passport_file_path_d
    local_cipher_obj.decrypt(@user_extended_detail.passport_file_path).data[:plaintext]
  end

  #
  # * Author: Kedar, Puneet
  # * Date: 12/10/2017
  # * Reviewed By: Sunil
  #
  def selfie_file_path_d
    local_cipher_obj.decrypt(@user_extended_detail.selfie_file_path).data[:plaintext]
  end

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

  #
  # * Author: Kedar, Puneet
  # * Date: 12/10/2017
  # * Reviewed By: Sunil
  #
  def nationality_d
    local_cipher_obj.decrypt(@user_extended_detail.nationality).data[:plaintext]
  end

  #
  # * Author: Kedar, Puneet
  # * Date: 12/10/2017
  # * Reviewed By: Sunil
  #
  def address_d
    [street_address_d, city_d, postal_code_d, state_d, country_of_residence_d].join(', ')
  end

  #
  # * Author: Kedar, Puneet
  # * Date: 12/10/2017
  # * Reviewed By: Sunil
  #
  def street_address_d
    local_cipher_obj.decrypt(@user_extended_detail.street_address).data[:plaintext]
  end

  #
  # * Author: Kedar, Puneet
  # * Date: 12/10/2017
  # * Reviewed By: Sunil
  #
  def city_d
    local_cipher_obj.decrypt(@user_extended_detail.city).data[:plaintext]
  end

  #
  # * Author: Kedar, Puneet
  # * Date: 12/10/2017
  # * Reviewed By: Sunil
  #
  def postal_code_d
    local_cipher_obj.decrypt(@user_extended_detail.postal_code).data[:plaintext]
  end

  #
  # * Author: Kedar, Puneet
  # * Date: 12/10/2017
  # * Reviewed By: Sunil
  #
  def state_d
    local_cipher_obj.decrypt(@user_extended_detail.state).data[:plaintext]
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

