module UserManagement

  class SignUp < ServicesBase

    # Initialize
    #
    # * Author: Kedar
    # * Date: 11/10/2017
    # * Reviewed By: Sunil Khedar
    #
    # @param [Integer] client_id (mandatory) - client id
    # @params [String] email (mandatory) - this is the email entered
    # @params [String] password (mandatory) - this is the password entered
    # @params [String] browser_user_agent (mandatory) - browser user agent
    # @params [String] ip_address (mandatory) - ip_address
    # @params [String] geoip_country (optional) - geoip_country
    # @params [Hash] utm_params (optional) - Utm Parameters for latest landing page if present
    #
    # @return [UserManagement::SignUp]
    #
    def initialize(params)
      super

      @client_id = @params[:client_id]
      @email = @params[:email]
      @password = @params[:password]
      @browser_user_agent = @params[:browser_user_agent]
      @ip_address = @params[:ip_address]
      @geoip_country = @params[:geoip_country]

      @utm_params = @params[:utm_params]

      @client = nil
      @client_token_sale_details = nil
      @login_salt_hash = nil
      @user_secret = nil
      @user = nil
    end

    # Perform
    #
    # * Author: Kedar
    # * Date: 11/10/2017
    # * Reviewed By: Sunil Khedar
    #
    # @return [Result::Base]
    #
    def perform

      r = validate_and_sanitize
      return r unless r.success?

      r = fetch_and_validate_client
      return r unless r.success?

      fetch_client_token_sale_details

      r = validate_client_details
      return r unless r.success?

      r = check_if_email_already_registered
      return r unless r.success?

      r = generate_login_salt
      return r unless r.success?

      create_user

      enqueue_job

      set_cookie_value

    end

    private

    # Validate and sanitize
    #
    # * Author: Kedar
    # * Date: 11/10/2017
    # * Reviewed By: Sunil Khedar
    #
    # @return [Result::Base]
    #
    def validate_and_sanitize

      @email = @email.to_s.downcase.strip

      validation_errors = {}
      if !Util::CommonValidateAndSanitize.is_valid_email?(@email)
        validation_errors[:email] = 'Please enter a valid email address'
      end

      if @password.length < 8
        validation_errors[:password] = 'Password should be minimum 8 characters'
      end

      return error_with_data(
          'um_su_1',
          'Registration Error',
          '',
          GlobalConstant::ErrorAction.default,
          {},
          validation_errors
      ) if validation_errors.present?

      # NOTE: To be on safe side, check for generic errors as well
      r = validate
      return r unless r.success?

      success
    end

    # Fetch token sale details
    #
    # * Author: Aman
    # * Date: 01/02/2018
    # * Reviewed By:
    #
    # @return [Result::Base]
    #
    def fetch_client_token_sale_details
      @client_token_sale_details = ClientTokenSaleDetail.get_from_memcache(@client_id)
    end

    # validate clients web hosting setup details and sale registration
    #
    # * Author: Aman
    # * Date: 01/02/2018
    # * Reviewed By:
    #
    # Sets @client
    #
    # @return [Result::Base]
    #
    def validate_client_details

      return error_with_data(
          'um_su_3',
          'Client is not active',
          'Client is not active',
          GlobalConstant::ErrorAction.default,
          {}
      ) if !@client.is_web_host_setup_done?

      return error_with_data(
          'um_su_4',
          'Registration has ended, it is no longer possible to signup now',
          'Registration has ended, it is no longer possible to signup now',
          GlobalConstant::ErrorAction.default,
          {},
          {}
      ) if @client_token_sale_details.has_registration_ended?

      success
    end

    # Check if email already registered
    #
    # * Author: Kedar
    # * Date: 11/10/2017
    # * Reviewed By: Sunil Khedar
    #
    # @return [Result::Base]
    #
    def check_if_email_already_registered
      user = User.where(client_id: @client_id, email: @email).first

      return error_with_data(
          'um_su_2',
          'Registration Error',
          '',
          GlobalConstant::ErrorAction.default,
          {},
          {email: 'Email address is already registered'}
      ) if user.present?

      success
    end

    # Generate login salt
    #
    # * Author: Kedar
    # * Date: 11/10/2017
    # * Reviewed By: Sunil Khedar
    #
    # Sets @login_salt_hash
    #
    # @return [Result::Base]
    #
    def generate_login_salt
      r = Aws::Kms.new('login', 'user').generate_data_key
      return r unless r.success?

      @login_salt_hash = r.data

      success
    end

    # Create user
    #
    # * Author: Kedar
    # * Date: 11/10/2017
    # * Reviewed By: Sunil Khedar
    #
    # Sets @user_secret, @user
    #
    # @return [Result::Base]
    #
    def create_user
      # first insert into user_secrets and use it's id in users table
      @user_secret = UserSecret.create!(login_salt: @login_salt_hash[:ciphertext_blob])

      password_e = User.get_encrypted_password(@password, @login_salt_hash[:plaintext])

      @user = User.new(
          client_id: @client_id,
          email: @email,
          password: password_e,
          user_secret_id: @user_secret.id,
          status: GlobalConstant::User.active_status,
          last_logged_in_at: Time.now.to_i
      )

      @user.send("set_" + GlobalConstant::User.doptin_mail_sent_property) if @client.is_verify_page_active_for_client?
      @user.save!
    end

    # Do remaining task in sidekiq
    #
    # * Author: Aman
    # * Date: 20/10/2017
    # * Reviewed By: Sunil
    #
    def enqueue_job
      BgJob.enqueue(
          SendDoubleOptIn,
          {
              client_id: @client_id,
              user_id: @user.id
          }
      )  if @client.is_verify_page_active_for_client?

      BgJob.enqueue(
          NewUserRegisterJob,
          {
              user_id: @user.id,
              utm_params: @utm_params,
              ip_address: @ip_address,
              browser_user_agent: @browser_user_agent,
              geoip_country: @geoip_country
          }
      )
    end

    # Set cookie value
    #
    # * Author: Kedar
    # * Date: 11/10/2017
    # * Reviewed By: Sunil Khedar
    #
    # Sets @cookie_value
    #
    # @return [Result::Base]
    #
    def set_cookie_value
      cookie_value = User.get_cookie_value(@user.id, @user.password, @browser_user_agent)
      success_with_data({cookie_value: cookie_value, user_token_sale_state: @user.get_token_sale_state_page_name})
    end

  end

end
