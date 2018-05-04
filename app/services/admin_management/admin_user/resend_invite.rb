module AdminManagement

  module AdminUser

    class ResendInvite < ServicesBase

      # Initialize
      #
      # * Author: Aman
      # * Date: 03/05/2018
      # * Reviewed By:
      #
      # @params [Integer] admin_id (mandatory) - logged in admin
      # @params [Integer] client_id (mandatory) - logged in admin's client id
      # @params [Integer] id (mandatory) - resend invite to admin id
      #
      # @return [AdminManagement::AdminUser::ResendInvite]
      #
      def initialize(params)
        super

        @admin_id = @params[:admin_id]
        @client_id = @params[:client_id]
        @invite_admin_id = @params[:id]

        @admin = nil
        @client = nil

        @invite_admin_obj = nil
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

        r = fetch_invite_admin
        return r unless r.success?

        r = create_invite_token
        return r unless r.success?

        send_invite

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

      # fetch admin if present
      #
      # * Author: Aman
      # * Date: 03/05/2018
      # * Reviewed By:
      #
      # sets @new_admin_obj
      #
      # @return [Result::Base]
      #
      def fetch_invite_admin
        @invite_admin_obj = Admin.where(id: @invite_admin_id, default_client_id: @client_id).first

        return error_with_data(
            'am_au_i_cialp_1',
            'Admin not found',
            'Invalid request. Admin not found',
            GlobalConstant::ErrorAction.default,
            {}
        ) if @invite_admin_obj.blank?

        return error_with_data(
            'am_au_i_cialp_2',
            'Admin state is not invite',
            'Admin user is active or deleted',
            GlobalConstant::ErrorAction.default,
            {}
        ) if @invite_admin_obj.status != GlobalConstant::Admin.invited_status

        success
      end

      # Create invite Token
      #
      # * Author: Aman
      # * Date: 03/05/2018
      # * Reviewed By:
      #
      # Sets @invite_token
      #
      # @return [Result::Base]
      #
      def create_invite_token
        admin_invite_token = Digest::MD5.hexdigest("#{@invite_admin_obj.id}::#{@invite_admin_obj.name}::#{Time.now.to_i}::invite_admin::#{rand}")
        db_row = TemporaryToken.create!(entity_id: @invite_admin_obj.id,
                                        kind: GlobalConstant::TemporaryToken.admin_invite_kind, token: admin_invite_token)

        admin_invite_token_str = "#{db_row.id.to_s}:#{admin_invite_token}"
        encryptor_obj = LocalCipher.new(GlobalConstant::SecretEncryptor.email_tokens_key)
        r = encryptor_obj.encrypt(admin_invite_token_str)
        return r unless r.success?

        @invite_token = r.data[:ciphertext_blob]

        success
      end

      # send invite to admin user
      #
      # * Author: Aman
      # * Date: 03/05/2018
      # * Reviewed By:
      #
      def send_invite

        Email::HookCreator::SendTransactionalMail.new(
            client_id: Client::OST_KYC_CLIENT_IDENTIFIER,
            email: @invite_admin_obj.email,
            template_name: GlobalConstant::PepoCampaigns.admin_invite_template,
            template_vars: {
                inviter_name: @admin.name,
                invitee_name: @invite_admin_obj.name,
                company_name: @client.name,
                invite_token: @invite_token

            }
        ).perform
      end

    end

  end

end
