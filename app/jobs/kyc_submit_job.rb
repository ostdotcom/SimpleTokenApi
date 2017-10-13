class KycSubmitJob < ApplicationJob

  queue_as GlobalConstant::Sidekiq.queue_name :default_high_priority_queue

  # Perform
  #
  # * Author: Kedar, Puneet
  # * Date: 12/10/2017
  # * Reviewed By: Sunil
  #
  def perform(params)

    init_params(params)

    create_email_service_api_call_hook

    associate_ued_with_user

    decrypt_kyc_salt

    call_cynopsis_api

  end

  private

  # Init params
  #
  # * Author: Kedar, Puneet
  # * Date: 12/10/2017
  # * Reviewed By: Sunil
  #
  def init_params(params)
    @user_id = params[:user_id]
    @is_re_submit = params[:is_re_submit]

    @user = User.find(@user_id)
    @user_extended_detail = UserExtendedDetail.where(user_id: @user_id).last

    @run_role = 'admin'
    @run_purpose = 'kyc'

    @kyc_salt_e = @user_extended_detail.kyc_salt
    @kyc_salt_d = nil
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

    return unless document_upload_needed?(r)

    upload_documents

  end

  #
  # * Author: Kedar, Puneet
  # * Date: 12/10/2017
  # * Reviewed By:
  #
  # @return [Boolean]
  #
  def document_upload_needed?(r)
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

    return true unless r.success?

    response_hash = ((r.data || {})[:response] || {})
    return true if response_hash['approval_status'].to_s == 'PENDING'

    false

  end

  #
  # * Author: Kedar, Puneet
  # * Date: 12/10/2017
  # * Reviewed By: Sunil
  #
  def upload_documents
    upload_document(passport_file_path_d, 'PASSPORT')
    upload_document(selfie_file_path_d, 'OTHERS', 'selfie')
    upload_document(residence_proof_file_path_d, 'OTHERS', 'residence_proof') if residence_proof_file_path_d.present?
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

    system("wget -O #{local_file_path} #{url}")

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
  def cynopsis_params
    {
      rfrID: "ts2_#{@user_id}",
      first_name: @user_extended_detail.first_name,
      last_name: @user_extended_detail.last_name,
      country_of_residence: country_of_residence_d.upcase,
      date_of_birth: Date.parse(date_of_birth_d).strftime("%d/%m/%Y"),
      identification_type: 'PASSPORT',
      identification_number: passport_number_d,
      nationality: nationality_d.update,
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

    success

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

