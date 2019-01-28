module AdminManagement
  
  module Login

    class AdminResetPassword < ServicesBase
  
      # Initialize
      #
      # * Author: Pankaj
      # * Date: 30/04/2018
      # * Reviewed By: 
      #
      # @params [String] r_t (mandatory) - token for reset
      # @params [String] password (mandatory) - this is the new password
      # @params [String] confirm_password (mandatory) - this is the confirm password
      #
      # @return [AdminManagement::Login::AdminResetPassword]
      #
      def initialize(params)
        super
  
        @r_t = @params[:r_t]
        @password = @params[:password]
        @confirm_password = @params[:confirm_password]

        @reset_token = nil
        @temporary_token_id = nil
        @temporary_token_obj = nil
        @admin = nil
        @admin_secret = nil
        @login_salt_d = nil
      end
  
      # Perform
      #
      # * Author: Pankaj
      # * Date: 30/04/2018
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
  
        r = fetch_admin
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
      # * Author: Pankaj
      # * Date: 30/04/2018
      # * Reviewed By: 
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
            'am_l_arp_1',
            'Invalid password',
            '',
            GlobalConstant::ErrorAction.default,
            {},
            validation_errors
        ) if validation_errors.present?
  
        return invalid_url_error('am_l_arp_2') if @r_t.blank?
  
        # NOTE: To be on safe side, check for generic errors as well
        r = validate
        return r unless r.success?
  
        decryptor_obj = LocalCipher.new(GlobalConstant::SecretEncryptor.email_tokens_key)
        r = decryptor_obj.decrypt(@r_t)
        return invalid_url_error('am_l_arp_4') unless r.success?
  
        decripted_t = r.data[:plaintext]
  
        splited_reset_token = decripted_t.split(':')
  
        return invalid_url_error('am_l_arp_3') if splited_reset_token.length != 2
  
        @reset_token = splited_reset_token[1].to_s
  
        @temporary_token_id = splited_reset_token[0].to_i
  
        success
      end
  
      # Fetch temporary token obj
      #
      # * Author: Pankaj
      # * Date: 30/04/2018
      # * Reviewed By: 
      #
      # Sets @temporary_token_obj
      #
      def fetch_temporary_token_obj
        @temporary_token_obj = TemporaryToken.where(id: @temporary_token_id).first
      end
  
      # Validate Token
      #
      # * Author: Pankaj
      # * Date: 30/04/2018
      # * Reviewed By: 
      #
      # @return [Result::Base]
      #
      def validate_reset_token
  
        return invalid_url_error('am_l_arp_4') if @temporary_token_obj.blank?
  
        return invalid_url_error('am_l_arp_5') if @temporary_token_obj.token != @reset_token
  
        return invalid_url_error('am_l_arp_6') if @temporary_token_obj.status != GlobalConstant::TemporaryToken.active_status
  
        return invalid_url_error('am_l_arp_7')  if @temporary_token_obj.is_expired?
  
        return invalid_url_error('am_l_arp_8') if @temporary_token_obj.kind != GlobalConstant::TemporaryToken.admin_reset_password_kind
  
        success
  
      end
  
      # Fetch Admin
      #
      # * Author: Pankaj
      # * Date: 30/04/2018
      # * Reviewed By: 
      #
      # Sets @admin, @admin_secret
      #
      # @return [Result::Base]
      #
      def fetch_admin
        @admin = Admin.where(id: @temporary_token_obj.entity_id).first
        return unauthorized_access_response_for_web('am_l_arp_9', 'Invalid Admin') unless @admin.present? &&
            @admin.password.present? &&
            (@admin.default_client_id == @temporary_token_obj.client_id) &&
            (@admin.status == GlobalConstant::Admin.active_status)

        @admin_secret = AdminSecret.where(id: @admin.admin_secret_id).first
        return unauthorized_access_response_for_web('am_l_arp_10', 'Invalid Admin') unless @admin_secret.present?
  
        success
      end
  
      # Decrypt login salt
      #
      # * Author: Pankaj
      # * Date: 30/04/2018
      # * Reviewed By: 
      #
      # Sets @login_salt_d
      #
      # @return [Result::Base]
      #
      def decrypt_login_salt
        r = Aws::Kms.new('login', 'admin').decrypt(@admin_secret.login_salt)
        return r unless r.success?
  
        @login_salt_d = r.data[:plaintext]
  
        success
      end
  
      # Update password
      #
      # * Author: Pankaj
      # * Date: 30/04/2018
      # * Reviewed By: 
      #
      def update_password
        @admin.password = Admin.get_encrypted_password(@password, @login_salt_d)
        @admin.save!
      end
  
      # Update active tokens
      #
      # * Author: Pankaj
      # * Date: 30/04/2018
      # * Reviewed By: 
      #
      def update_token_status
        @temporary_token_obj.status = GlobalConstant::TemporaryToken.used_status
        @temporary_token_obj.save!
  
        TemporaryToken.where(
            client_id: @temporary_token_obj.client_id,
            entity_id: @admin.id,
            kind: GlobalConstant::TemporaryToken.admin_reset_password_kind,
            status: GlobalConstant::TemporaryToken.active_status
        ).update_all(
            status: GlobalConstant::TemporaryToken.inactive_status
        )
        success
      end
  
      # Invalid Request Response
      #
      # * Author: Pankaj
      # * Date: 30/04/2018
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

end
