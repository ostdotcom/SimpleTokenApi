module AdminManagement
  
  module AdminUser

    class ActivateInvitedAdmin < ServicesBase
  
      # Initialize
      #
      # * Author: Aman
      # * Date: 03/05/2018
      # * Reviewed By:
      #
      # @params [String] i_t (mandatory) - token for invite
      # @params [String] password (mandatory) - this is the new password
      # @params [String] confirm_password (mandatory) - this is the confirm password
      #
      # @return [AdminManagement::AdminUser::ActivateInvitedAdmin]
      #
      def initialize(params)
        super
  
        @i_t = @params[:i_t]
        @password = @params[:password]
        @confirm_password = @params[:confirm_password]

        @invite_token = nil
        @temporary_token_id = nil
        @temporary_token_obj = nil
        @admin = nil
      end
  
      # Perform
      #
      # * Author: Aman
      # * Date: 03/05/2018
      # * Reviewed By:
      #
      # @return [Result::Base]
      #
      def perform
  
        r = validate_and_sanitize
        return r unless r.success?
  
        fetch_temporary_token_obj
  
        r = validate_invite_token
        return r unless r.success?
  
        r = fetch_admin
        return r unless r.success?
  
        r = update_admin
        return r unless r.success?
  
        r = update_token_status
        return r unless r.success?
  
        success
  
      end
  
      private
  
      # Validate and sanitize
      #
      # * Author: Aman
      # * Date: 03/05/2018
      # * Reviewed By:
      #
      # Sets @invite_token, @temporary_token_id
      #
      # @return [Result::Base]
      #
      def validate_and_sanitize
  
        validation_errors = {}
  
        validation_errors[:password] = 'Password should be minimum 8 characters' if @password.length < 8
        validation_errors[:confirm_password] = 'Passwords do not match' if @confirm_password != @password
  
        return error_with_data(
            'am_au_aia_vas_1',
            'Invalid password',
            '',
            GlobalConstant::ErrorAction.default,
            {},
            validation_errors
        ) if validation_errors.present?
  
        return invalid_url_error('am_au_aia_vas_2') if @i_t.blank?
  
        # NOTE: To be on safe side, check for generic errors as well
        r = validate
        return r unless r.success?
  
        decryptor_obj = LocalCipher.new(GlobalConstant::SecretEncryptor.email_tokens_key)
        r = decryptor_obj.decrypt(@i_t)
        return r unless r.success?
  
        decripted_t = r.data[:plaintext]
  
        splited_invite_token = decripted_t.split(':')
  
        return invalid_url_error('am_au_aia_vas_3') if splited_invite_token.length != 2
  
        @invite_token = splited_invite_token[1].to_s
  
        @temporary_token_id = splited_invite_token[0].to_i
  
        success
      end
  
      # Fetch temporary token obj
      #
      # * Author: Aman
      # * Date: 03/05/2018
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
      # * Date: 03/05/2018
      # * Reviewed By:
      #
      # @return [Result::Base]
      #
      def validate_invite_token
  
        return invalid_url_error('am_au_aia_vit_1') if @temporary_token_obj.blank?
  
        return invalid_url_error('am_au_aia_vit_2') if @temporary_token_obj.token != @invite_token
  
        return invalid_url_error('am_au_aia_vit_3') if @temporary_token_obj.status != GlobalConstant::TemporaryToken.active_status
  
        return invalid_url_error('am_au_aia_vit_4')  if @temporary_token_obj.is_expired?
  
        return invalid_url_error('am_au_aia_vit_5') if @temporary_token_obj.kind != GlobalConstant::TemporaryToken.admin_invite_kind
  
        success
  
      end
  
      # Fetch Admin
      #
      # * Author: Aman
      # * Date: 03/05/2018
      # * Reviewed By:
      #
      # Sets @admin
      #
      # @return [Result::Base]
      #
      def fetch_admin
        @admin = Admin.where(id: @temporary_token_obj.entity_id).first
        return unauthorized_access_response_for_web('am_au_aia_fa_1', 'Invalid Admin User') unless @admin.present? &&
            @admin.status == GlobalConstant::Admin.invited_status

        success
      end
  
      # Generate login salt and admin secret obj
      #
      # * Author: Aman
      # * Date: 03/05/2018
      # * Reviewed By:
      #
      # @return [Result::Base]
      #
      def update_admin

        ga_secret = ROTP::Base32.random_base32

        #get cmk key and text
        kms_login_client = Aws::Kms.new('login', 'admin')
        resp = kms_login_client.generate_data_key
        return resp unless resp.success?

        ciphertext_blob = resp.data[:ciphertext_blob]
        login_salt_d = resp.data[:plaintext]

        encrypted_password = Admin.get_encrypted_password(@password, login_salt_d)
        encryptor_obj = LocalCipher.new(login_salt_d)

        #get encrypted_ga_secret
        r = encryptor_obj.encrypt(ga_secret)
        return r unless r.success?
        encrypted_ga_secret = r.data[:ciphertext_blob]

        #create admin secrets
        admin_secret_obj = AdminSecret.new(login_salt: ciphertext_blob, ga_secret: encrypted_ga_secret)
        admin_secret_obj.save!(validate: false)

        @admin.password = encrypted_password
        @admin.admin_secret_id = admin_secret_obj.id
        @admin.status =  GlobalConstant::Admin.active_status
        @admin.set_default_notification_types
        @admin.save!(validate: false)
  
        success
      end
  
      # Update active tokens
      #
      # * Author: Aman
      # * Date: 03/05/2018
      # * Reviewed By:
      #
      def update_token_status
        @temporary_token_obj.status = GlobalConstant::TemporaryToken.used_status
        @temporary_token_obj.save!
  
        TemporaryToken.where(
            entity_id: @admin.id,
            kind: GlobalConstant::TemporaryToken.admin_invite_kind,
            status: GlobalConstant::TemporaryToken.active_status
        ).update_all(
            status: GlobalConstant::TemporaryToken.inactive_status
        )
        success
      end
  
      # Invalid Request Response
      #
      # * Author: Aman
      # * Date: 03/05/2018
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
