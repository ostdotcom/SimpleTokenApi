module UserManagement

  class ResetPassword < ServicesBase

    # Initialize
    #
    # * Author: Aman
    # * Date: 13/10/2017
    # * Reviewed By: Sunil
    #
    # @param [AR] client (mandatory) - client obj
    # @params [String] r_t (mandatory) - token for reset
    # @params [String] password (mandatory) - this is the new password
    # @params [String] confirm_password (mandatory) - this is the confirm password
    #
    # @return [UserManagement::ResetPassword]
    #
    def initialize(params)
      super

      @r_t = @params[:r_t]
      @password = @params[:password]
      @confirm_password = @params[:confirm_password]
      @client = @params[:client]

      @client_id = @client.id
      @reset_token = nil
      @temporary_token_id = nil
      @temporary_token_obj = nil
      @user = nil
      @user_secret = nil
      @login_salt_d = nil
    end

    # Perform
    #
    # * Author: Aman
    # * Date: 13/10/2017
    # * Reviewed By: Sunil
    #
    # @return [Result::Base]
    #
    def perform

      r = validate_and_sanitize
      return r unless r.success?

      r = validate_client_details
      return r unless r.success?

      fetch_temporary_token_obj

      r = validate_reset_token
      return r unless r.success?

      r = fetch_user
      return r unless r.success?

      r = decrypt_login_salt
      return r unless r.success?

      update_password

      r = update_token_status
      return r unless r.success?

      success

    end

    private

    # Validate and sanitize
    #
    # * Author: Aman
    # * Date: 13/10/2017
    # * Reviewed By: Sunil
    #
    # Sets @reset_token, @temporary_token_id
    #
    # @return [Result::Base]
    #
    def validate_and_sanitize

      validation_errors = {}

      validation_errors[:password] = 'Password should be minimum 8 characters' if @password.length < 8
      validation_errors[:confirm_password] = 'Passwords do not match' if @confirm_password != @password

      return error_with_data(
          'um_cp_1',
          'Invalid password',
          '',
          GlobalConstant::ErrorAction.default,
          {},
          validation_errors
      ) if validation_errors.present?

      return invalid_url_error('um_rp_2') if @r_t.blank?

      # NOTE: To be on safe side, check for generic errors as well
      r = validate
      return r unless r.success?

      decryptor_obj = LocalCipher.new(GlobalConstant::SecretEncryptor.email_tokens_key)
      r = decryptor_obj.decrypt(@r_t)
      return invalid_url_error('um_rp_4') unless r.success?

      decripted_t = r.data[:plaintext]

      splited_reset_token = decripted_t.split(':')

      return invalid_url_error('um_rp_3') if splited_reset_token.length != 2

      @reset_token = splited_reset_token[1].to_s

      @temporary_token_id = splited_reset_token[0].to_i

      success
    end

    # validate clients web hosting setup details
    #
    # * Author: Aman
    # * Date: 26/12/2017
    # * Reviewed By:
    #
    # Sets @client
    #
    # @return [Result::Base]
    #
    def validate_client_details
      return error_with_data(
          'um_rp_12',
          'Client is not active',
          'Client is not active',
          GlobalConstant::ErrorAction.default,
          {}
      ) if !@client.is_web_host_setup_done?

      success
    end

    # Fetch temporary token obj
    #
    # * Author: Aman
    # * Date: 13/10/2017
    # * Reviewed By: Sunil
    #
    # Sets @temporary_token_obj
    #
    def fetch_temporary_token_obj
      @temporary_token_obj = TemporaryToken.where(id: @temporary_token_id).first
    end

    # Validate Token
    #
    # * Author: Aman
    # * Date: 13/10/2017
    # * Reviewed By: Sunil
    #
    # @return [Result::Base]
    #
    def validate_reset_token

      return invalid_url_error('um_rp_4') if @temporary_token_obj.blank?

      return invalid_url_error('um_rp_5') if @temporary_token_obj.token != @reset_token

      return invalid_url_error('um_rp_6') if @temporary_token_obj.status != GlobalConstant::TemporaryToken.active_status

      return invalid_url_error('um_rp_7')  if @temporary_token_obj.is_expired?

      return invalid_url_error('um_rp_8') if @temporary_token_obj.kind != GlobalConstant::TemporaryToken.reset_password_kind

      success

    end

    # Fetch user
    #
    # * Author: Aman
    # * Date: 13/10/2017
    # * Reviewed By: Sunil
    #
    # Sets @user, @user_secret
    #
    # @return [Result::Base]
    #
    def fetch_user
      @user = User.using_client_shard(client: @client).get_from_memcache(@temporary_token_obj.entity_id)
      return unauthorized_access_response_for_web('um_rp_9','Invalid User') unless @user.present? && @user.password.present? &&
          (@user.status == GlobalConstant::User.active_status)

      return unauthorized_access_response_for_web('um_rp_11','Invalid User') if @user.client_id != @client_id

      @user_secret = UserSecret.using_client_shard(client: @client).where(id: @user.user_secret_id).first
      return unauthorized_access_response_for_web('um_rp_10','Invalid User') unless @user_secret.present?

      success
    end

    # Decrypt login salt
    #
    # * Author: Aman
    # * Date: 13/10/2017
    # * Reviewed By: Sunil
    #
    # Sets @login_salt_d
    #
    # @return [Result::Base]
    #
    def decrypt_login_salt
      r = Aws::Kms.new('login', 'user').decrypt(@user_secret.login_salt)
      return r unless r.success?

      @login_salt_d = r.data[:plaintext]

      success
    end

    # Update password
    #
    # * Author: Aman
    # * Date: 13/10/2017
    # * Reviewed By: Sunil
    #
    def update_password
      @user.password = User.get_encrypted_password(@password, @login_salt_d)
      @user.save!
    end

    # Update active tokens
    #
    # * Author: Aman
    # * Date: 13/10/2017
    # * Reviewed By: Sunil
    #
    def update_token_status
      @temporary_token_obj.status = GlobalConstant::TemporaryToken.used_status
      @temporary_token_obj.save!

      TemporaryToken.where(
          entity_id: @user.id,
          kind: GlobalConstant::TemporaryToken.reset_password_kind,
          status: GlobalConstant::TemporaryToken.active_status
      ).update_all(
          status: GlobalConstant::TemporaryToken.inactive_status
      )
      success
    end

    # Invalid Request Response
    #
    # * Author: Aman
    # * Date: 13/10/2017
    # * Reviewed By: Sunil
    #
    # @return [Result::Base]
    #
    def invalid_url_error(code)
      error_with_data(
          code,
          'Invalid URL',
          'Invalid URL',
          GlobalConstant::ErrorAction.default,
          {}
      )
    end

  end

end
