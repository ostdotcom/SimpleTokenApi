module AdminManagement

  module Login

    class SendAdminResetPasswordLink < ServicesBase

      # Initialize
      #
      # * Author: Pankaj
      # * Date: 30/04/2018
      # * Reviewed By:
      #
      # @param [Integer] client_id (mandatory) - client id
      # @params [String] email (mandatory) - this is the email entered
      #
      # @return [AdminManagement::Login::SendAdminResetPasswordLink]
      #
      def initialize(params)
        super

        @email = @params[:email]
        @client_id = @params[:client_id]

        @client = nil
        @admin = nil
        @reset_password_token = nil
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

        r = validate
        return r unless r.success?

        r = fetch_and_validate_client
        return r unless r.success?

        r = validate_client_details
        return r unless r.success?

        r = fetch_admin
        return r unless r.success?

        r = create_reset_password_token
        return r  unless r.success?

        send_forgot_password_mail

        success
      end

      private

      # validate clients web hosting setup details
      #
      # * Author: Pankaj
      # * Date: 30/04/2018
      # * Reviewed By:
      #
      # @return [Result::Base]
      #
      def validate_client_details

        return error_with_data(
            'ad_l_sarpl_1',
            'Client is not active',
            'Client is not active',
            GlobalConstant::ErrorAction.default,
            {}
        ) if !@client.is_web_host_setup_done?

        success
      end

      # Fetch Admin
      #
      # * Author: Pankaj
      # * Date: 30/04/2018
      # * Reviewed By:
      #
      # Sets @admin
      #
      # @return [Result::Base]
      #
      def fetch_admin
        @admin = Admin.where(default_client_id: @client_id, email: @email).first

        return error_with_data(
            'ad_l_sarpl_2',
            'User not present',
            '',
            GlobalConstant::ErrorAction.default,
            {},
            {email: 'This user is not registered or is blocked'}
        ) unless @admin.present? && @admin.password.present? && (@admin.status == GlobalConstant::Admin.active_status)

        success
      end

      # Create Double Opt In Token
      #
      # * Author: Pankaj
      # * Date: 30/04/2018
      # * Reviewed By:
      #
      # Sets @reset_password_token
      #
      # @return [Result::Base]
      #
      def create_reset_password_token
        reset_token = Digest::MD5.hexdigest("#{@admin.id}::#{@admin.password}::#{Time.now.to_i}::reset_password::#{rand}")
        db_row = TemporaryToken.create!(user_id: @admin.id, kind: GlobalConstant::TemporaryToken.admin_reset_password_kind, token: reset_token)

        reset_pass_token_str = "#{db_row.id.to_s}:#{reset_token}"
        encryptor_obj = LocalCipher.new(GlobalConstant::SecretEncryptor.email_tokens_key)
        r = encryptor_obj.encrypt(reset_pass_token_str)
        return r unless r.success?

        @reset_password_token = r.data[:ciphertext_blob]

        success
      end

      # Send forgot password_mail
      #
      # * Author: Pankaj
      # * Date: 30/04/2018
      # * Reviewed By:
      #
      # TODO:: Confirm if Reset password template would be different for admins.
      def send_forgot_password_mail
        Email::HookCreator::SendTransactionalMail.new(
            client_id: @client_id,
            email: @admin.email,
            template_name: GlobalConstant::PepoCampaigns.forgot_password_template,
            template_vars: {
                reset_password_token: @reset_password_token
            }
        ).perform
      end

    end

  end
end
