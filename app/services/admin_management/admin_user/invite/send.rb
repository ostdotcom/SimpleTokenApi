module AdminManagement

  module AdminUser

    module Invite

      class Send < Base

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
        # @return [AdminManagement::AdminUser::Invite::Send]
        #
        def initialize(params)
          super

          @email = @params[:email]
          @name = @params[:name]
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
          super
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
          r = super
          return r unless r.success?

          @email = @email.to_s.downcase.strip
          @name = @name.to_s.downcase.strip

          return error_with_data(
              'am_au_i_vas_1',
              'Invite User Error',
              'Please enter a valid email address',
              GlobalConstant::ErrorAction.default,
              {}
          ) if !Util::CommonValidateAndSanitize.is_valid_email?(@email)

          return error_with_data(
              'am_au_i_vas_2',
              'Invite User Error',
              'Name cannot be blank',
              GlobalConstant::ErrorAction.default,
              {}
          ) if @name.blank?

          return error_with_data(
              'am_au_i_vas_3',
              'Invite User Error',
              'Name can be of maximum 100 characters',
              GlobalConstant::ErrorAction.default,
              {}
          ) if @name.length > 100

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
          r = check_max_allowed_admin_count
          return r unless r.success?

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
        def fetch_invite_admin
          r = check_if_admin_already_present
          return r unless r.success?

          add_or_update_admin
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
          # find max allowed admins by admin role
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

        # fetch admin if present
        #
        # * Author: Aman
        # * Date: 03/05/2018
        # * Reviewed By:
        #
        # sets @invite_admin_obj
        #
        # @return [Result::Base]
        #
        def check_if_admin_already_present
          # what if existing admin is normal or super?
          # If current role of admin is normal, if want to make it super. will that be allowed?
          @invite_admin_obj = Admin.where(email: @email).first
          return success if @invite_admin_obj.blank?

          return error_with_data(
              'am_au_i_cialp_1',
              'Admin already has an account with a different client',
              'Admin user is alreay associated with some other client',
              GlobalConstant::ErrorAction.default,
              {}
          ) if @invite_admin_obj.default_client_id != @client_id

          return error_with_data(
              'am_au_i_cialp_2',
              'Admin already active',
              'Admin user is alreay active',
              GlobalConstant::ErrorAction.default,
              {}
          ) if @invite_admin_obj.status == GlobalConstant::Admin.active_status

          success
        end

        # Add or update admin status to invited
        #
        # * Author: Aman
        # * Date: 03/05/2018
        # * Reviewed By:
        #
        def add_or_update_admin
          # add or update based on role instead of hardcoded normal admin role.
          if @invite_admin_obj.blank?
            @invite_admin_obj = Admin.new(email: @email, default_client_id: @client_id)
          end

          @invite_admin_obj.status = GlobalConstant::Admin.invited_status
          @invite_admin_obj.role = GlobalConstant::Admin.normal_admin_role
          @invite_admin_obj.name = @name

          @invite_admin_obj.save! if @invite_admin_obj.changed?
        end

      end

    end
  end
end
