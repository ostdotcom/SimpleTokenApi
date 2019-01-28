module AdminManagement

  module Login

    class SendAdminResetPasswordLink < ServicesBase

      # Initialize
      #
      # * Author: Pankaj
      # * Date: 30/04/2018
      # * Reviewed By:
      #
      # @params [String] email (mandatory) - this is the email entered
      #
      # @return [AdminManagement::Login::SendAdminResetPasswordLink]
      #
      def initialize(params)
        super

        @email = @params[:email]

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

        r = fetch_admin
        # do not send a different error response if admin email not present
        return success unless r.success?

        r = create_reset_password_token
        return r unless r.success?

        send_forgot_password_mail

        success
      end

      private

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
        @admin = Admin.where(email: @email).first

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
        db_row = TemporaryToken.create!({
                                            client_id: @admin.default_client_id,
                                            entity_id: @admin.id,
                                            kind: GlobalConstant::TemporaryToken.admin_reset_password_kind,
                                            token: reset_token
                                        })

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
      def send_forgot_password_mail
        Email::HookCreator::SendTransactionalMail.new(
            client_id: Client::OST_KYC_CLIENT_IDENTIFIER,
            email: @admin.email,
            template_name: GlobalConstant::PepoCampaigns.admin_forgot_password_template,
            template_vars: {
                reset_password_token: @reset_password_token
            }
        ).perform
      end

    end

  end
end
