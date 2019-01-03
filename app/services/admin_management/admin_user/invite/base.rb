module AdminManagement

  module AdminUser

    module Invite

      class Base < ServicesBase

        # Initialize
        #
        # * Author: Aman
        # * Date: 03/05/2018
        # * Reviewed By:
        #
        # @params [Integer] admin_id (mandatory) - logged in admin
        # @params [Integer] client_id (mandatory) - logged in admin's client id
        # @params [Integer] email (mandatory) - new admin user email
        # @params [Integer] name (mandatory) - new admin user name
        #
        # @return [AdminManagement::AdminUser::Invite::Base]
        #
        def initialize(params)
          super

          @admin_id = @params[:admin_id]
          @client_id = @params[:client_id]

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

          r = extra_validations
          return r unless r.success?

          r = fetch_invite_admin
          return r unless r.success?

          r = create_invite_token
          return r unless r.success?

          send_invite

          success_with_data({})
        end

        private

        # validate and sanitize
        #
        # * Author: Aman
        # * Date: 03/05/2018
        # * Reviewed By:
        #
        # @return [Result::Base]
        #
        def validate_and_sanitize
          r = validate
          return r unless r.success?
          success
        end

        # extra validations if needed
        #
        # * Author: Aman
        # * Date: 03/05/2018
        # * Reviewed By:
        #
        # @return [Result::Base]
        #
        def extra_validations
          success
        end

        # parent class to define this function
        #
        # * Author: Aman
        # * Date: 03/05/2018
        # * Reviewed By:
        #
        # @return [Result::Base]
        #
        def fetch_invite_admin
          fail "undefined method fetch_invite_admin in parent class"
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
                                          status: GlobalConstant::TemporaryToken.active_status,
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
          # pass role of admin
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
end
