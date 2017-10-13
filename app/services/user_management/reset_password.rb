module UserManagement

  class ResetPassword < ServicesBase

    # Initialize
    #
    # * Author: Aman
    # * Date: 13/10/2017
    # * Reviewed By:
    #
    # @param [String] r_t (mandatory) - token for reset
    # @param [String] password (mandatory) - this is the new password
    # @param [String] confirm_password (mandatory) - this is the confirm password
    #
    # @return [UserManagement::ResetPassword]
    #
    def initialize(params)
      super

      @r_t = @params[:r_t]
      @password = @params[:password]
      @confirm_password = @params[:confirm_password]

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
    # * Reviewed By:
    #
    # @return [Result::Base]
    #
    def perform

      r = validate_and_sanitize
      return r unless r.success?

      fetch_temporary_token_obj

      r = validate_reset_token
      return r unless r.success?

      r = fetch_user
      return r unless r.success?

      r = decrypt_login_salt
      return r unless r.success?

      r = update_password
      return r unless r.success?

      r = invalidate_reset_token
      return r unless r.success?

      success

    end

    private

    # Validate and sanitize
    #
    # * Author: Aman
    # * Date: 13/10/2017
    # * Reviewed By:
    #
    # Sets @reset_token, @temporary_token_id
    #
    # @return [Result::Base]
    #
    def validate_and_sanitize

      validation_errors = {}

      validation_errors[:password] = "Password should be minimum 8 characters" if @password.length < 8
      validation_errors[:confirm_password] = "Passwords do not match" if @confirm_password != @password

      return error_with_data(
          'um_cp_1',
          'Invalid Parameters',
          'Please provide valid passwords',
          GlobalConstant::ErrorAction.default,
          {},
          validation_errors
      ) if validation_errors.present?

      return invalid_url_error('um_rp_1') if @r_t.blank?

      splited_reset_token = @r_t.split(':')

      return invalid_url_error('um_rp_2') if splited_reset_token.length != 2

      @reset_token = splited_reset_token[1].to_s

      @temporary_token_id = splited_reset_token[0].to_i

      success
    end

    # Fetch temporary token obj
    #
    # * Author: Aman
    # * Date: 13/10/2017
    # * Reviewed By:
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
    # * Reviewed By:
    #
    # @return [Result::Base]
    #
    def validate_reset_token

      return invalid_url_error('um_rp_3') if @temporary_token_obj.blank?

      return invalid_url_error('um_rp_4') if @temporary_token_obj.token != @reset_token

      return invalid_url_error('um_rp_5') if @temporary_token_obj.status != GlobalConstant::TemporaryToken.active_status

      return invalid_url_error('um_rp_6')  if @temporary_token_obj.is_expired?

      success

    end

    # Fetch user
    #
    # * Author: Aman
    # * Date: 13/10/2017
    # * Reviewed By:
    #
    # Sets @user, @user_secret
    #
    # @return [Result::Base]
    #
    def fetch_user
      @user = User.where(id: @temporary_token_obj.user_id).first
      return unauthorized_access_response('um_rp_7') unless @user.present?

      @user_secret = UserSecret.where(id: @user.user_secret_id).first
      return unauthorized_access_response('um_rp_8') unless @user_secret.present?

      success
    end

    # Decrypt login salt
    #
    # * Author: Aman
    # * Date: 13/10/2017
    # * Reviewed By:
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
    # * Reviewed By:
    #
    def update_password
      @user.password = User.get_encrypted_password(@password, @login_salt_d)
      @user.save!
    end

    # Update password
    #
    # * Author: Aman
    # * Date: 13/10/2017
    # * Reviewed By:
    #
    def invalidate_reset_token
      @temporary_token_obj.status = GlobalConstant::TemporaryToken.used_status
      @temporary_token_obj.save!
    end

    # Invalid User access response
    #
    # * Author: Aman
    # * Date: 13/10/2017
    # * Reviewed By:
    #
    # @return [Result::Base]
    #
    def unauthorized_access_response(err, display_text = 'Invalid User')
      error_with_data(
          err,
          display_text,
          display_text,
          GlobalConstant::ErrorAction.default,
          {}
      )
    end

    # Invalid Request Response
    #
    # * Author: Aman
    # * Date: 13/10/2017
    # * Reviewed By:
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
