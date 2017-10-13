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
    @is_re_submit ? create_call_cynopsis_api : update_cynopsis_case
    create_cynopsis_case
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
      country_of_residence: country_of_residence_d,
      date_of_birth: date_of_birth_d,
      identification_type: 'PASSPORT',
      identification_number: passport_number_d,
      nationality: nationality_d,
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
