module AdminManagement

  module AdminUser

    class ResetMfa < ServicesBase

      # Initialize
      #
      # * Author: Aman
      # * Date: 03/05/2018
      # * Reviewed By:
      #
      # @params [Integer] admin_id (mandatory) - logged in admin
      # @params [Integer] client_id (mandatory) - logged in admin's client id
      # @params [Integer] id (mandatory) -  admin id to reset mfa code
      #
      # @return [AdminManagement::AdminUser::ResetMfa]
      #
      def initialize(params)
        super

        @admin_id = @params[:admin_id]
        @client_id = @params[:client_id]
        @reset_admin_id = @params[:id]

        @admin = nil
        @admin_secret_obj = nil
        @client = nil

        @reset_admin_obj = nil
        @invite_token = nil
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

        r = fetch_and_validate_client
        return r unless r.success?

        r = fetch_and_validate_admin
        return r unless r.success?

        r = fetch_admin_to_reset
        return r unless r.success?

        r = fetch_admin_secret_obj
        return r unless r.success?

        r = reset_mfa
        return r unless r.success?

        success_with_data({})
      end

      private

      # Perform
      #
      # * Author: Aman
      # * Date: 03/05/2018
      # * Reviewed By:
      #
      # @return [Result::Base]
      #
      def validate_and_sanitize
        validate
      end

      # fetch admin
      #
      # * Author: Aman
      # * Date: 03/05/2018
      # * Reviewed By:
      #
      # sets @reset_admin_obj
      #
      # @return [Result::Base]
      #
      def fetch_admin_to_reset
        @reset_admin_obj = Admin.where(id: @reset_admin_id, default_client_id: @client_id).first

        return error_with_data(
            'am_au_rm_fatr_1',
            'Admin not found',
            'Invalid request. Admin not found',
            GlobalConstant::ErrorAction.default,
            {}
        ) if @reset_admin_obj.blank?

        return error_with_data(
            'am_au_rm_fatr_2',
            'Admin state is not active',
            'Admin user is not active',
            GlobalConstant::ErrorAction.default,
            {}
        ) if @reset_admin_obj.status != GlobalConstant::Admin.active_status

        success
      end

      # fetch admin secret obj
      #
      # * Author: Aman
      # * Date: 03/05/2018
      # * Reviewed By:
      #
      # sets @new_admin_obj
      #
      # @return [Result::Base]
      #
      def fetch_admin_secret_obj
        @admin_secret_obj = AdminSecret.get_from_memcache(@reset_admin_obj.admin_secret_id)

        return error_with_data(
            'am_au_rm_faso_1',
            'Admin secret not found',
            'Admin is not active',
            GlobalConstant::ErrorAction.default,
            {}
        ) if @admin_secret_obj.blank?

        success
      end

      # Resets MFA token of admin
      #
      # * Author: Aman
      # * Date: 03/05/2018
      # * Reviewed By:
      #
      # @return [Result::Base]
      #
      def reset_mfa
        login_salt_d = @admin_secret_obj.login_salt_decrypted

        encryptor_obj = LocalCipher.new(login_salt_d)
        ga_secret = ROTP::Base32.random_base32

        #get encrypted_ga_secret
        r = encryptor_obj.encrypt(ga_secret)
        return r unless r.success?
        encrypted_ga_secret = r.data[:ciphertext_blob]

        @admin_secret_obj.ga_secret = encrypted_ga_secret
        @admin_secret_obj.save!

        @reset_admin_obj.last_otp_at = nil
        @reset_admin_obj.save! if @reset_admin_obj.changed?

        success
      end


    end

  end

end
