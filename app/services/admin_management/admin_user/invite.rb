module AdminManagement

  module AdminUser

    class Invite < ServicesBase

      MAX_ADMINS = 20

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
      # @return [AdminManagement::AdminUser::Invite]
      #
      def initialize(params)
        super

        @admin_id = @params[:admin_id]
        @client_id = @params[:client_id]
        @email = @params[:email]
        @name = @params[:name]

        @admin = nil
        @client = nil

        @new_admin_obj = nil
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

        r = check_if_admin_already_present
        return r unless r.success?

        r = check_max_allowed_admin_count
        return r unless r.success?

        add_or_update_admin

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
        r = validate
        return r unless r.success?

        @email = @email.to_s.downcase.strip
        @name = @name.to_s.downcase.strip

        validation_errors = {}
        if !Util::CommonValidator.is_valid_email?(@email)
          validation_errors[:email] = 'Please enter a valid email address'
        end

        if @name.length > 100
          validation_errors[:name] = 'name can be maximum 100 characters'
        end

        return error_with_data(
            'am_au_i_vas_1',
            'Invite User Error',
            '',
            GlobalConstant::ErrorAction.default,
            {},
            validation_errors
        ) if validation_errors.present?

        success
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
      def check_if_admin_already_present
        @new_admin_obj = Admin.where(email: @email).first
        return success if @new_admin_obj.blank?

        return error_with_data(
            'am_au_i_cialp_1',
            'Admin already has an account with a different client',
            'Admin user is alreay associated with some other client',
            GlobalConstant::ErrorAction.default,
            {}
        ) if @new_admin_obj.default_client_id != @client_id

        return error_with_data(
            'am_au_i_cialp_2',
            'Admin already active',
            'Admin user is alreay active',
            GlobalConstant::ErrorAction.default,
            {}
        ) if @new_admin_obj.status == GlobalConstant::Admin.active_status

        success
      end

      # check if total no admins allowed for a client has reached
      #
      # * Author: Aman
      # * Date: 03/05/2018
      # * Reviewed By:
      #
      # @return [Result::Base]
      #
      def check_max_allowed_admin_count
        total = Admin.not_deleted.where(default_client_id: @client_id).count

        return error_with_data(
            'am_au_i_cmaac_1',
            'total no of admins added has reached max limit',
            "You can add only upto #{MAX_ADMINS} admins",
            GlobalConstant::ErrorAction.default,
            {}
        ) if total.to_i >= MAX_ADMINS

        success
      end

      # Add or update admin status to invited
      #
      # * Author: Aman
      # * Date: 03/05/2018
      # * Reviewed By:
      #
      def add_or_update_admin
        if @new_admin_obj.blank?
          @new_admin_obj = Admin.new(email: @email, default_client_id: @client_id)
        end

        @new_admin_obj.status = GlobalConstant::Admin.invited_status
        @new_admin_obj.role = GlobalConstant::Admin.normal_admin_role
        @new_admin_obj.name = @name

        @new_admin_obj.save! if @new_admin_obj.changed?
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
        admin_invite_token = Digest::MD5.hexdigest("#{@new_admin_obj.id}::#{@new_admin_obj.name}::#{Time.now.to_i}::invite_admin::#{rand}")
        db_row = TemporaryToken.create!(user_id: @new_admin_obj.id,
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
            email: @new_admin_obj.email,
            template_name: GlobalConstant::PepoCampaigns.admin_invite_template,
            template_vars: {
                inviter_name: @admin.name,
                invitee_name: @new_admin_obj.name,
                company_name: @client.name,
                invite_token: @invite_token

            }
        ).perform

      end

    end

  end

end
