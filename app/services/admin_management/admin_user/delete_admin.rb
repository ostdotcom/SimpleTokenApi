module AdminManagement

  module AdminUser

    class DeleteAdmin < ServicesBase

      # Initialize
      #
      # * Author: Aman
      # * Date: 03/05/2018
      # * Reviewed By:
      #
      # @params [Integer] admin_id (mandatory) - logged in admin
      # @params [Integer] client_id (mandatory) - logged in admin's client id
      # @params [Integer] id (mandatory) - soft delete admin id
      #
      # @return [AdminManagement::AdminUser::DeleteAdmin]
      #
      def initialize(params)
        super

        @admin_id = @params[:admin_id]
        @client_id = @params[:client_id]
        @delete_admin_id = @params[:id]

        @admin = nil
        @client = nil

        @delete_admin_obj = nil
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

        r = fetch_admin_to_delete
        return r unless r.success?

        update_admin

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
      # sets @delete_admin_obj
      #
      # @return [Result::Base]
      #
      def fetch_admin_to_delete
        @delete_admin_obj = Admin.where(id: @delete_admin_id, default_client_id: @client_id).first

        return error_with_data(
            'am_au_da_fatd_1',
            'Admin not found',
            'Invalid request. Admin not found',
            GlobalConstant::ErrorAction.default,
            {}
        ) if @delete_admin_obj.blank?

        return error_with_data(
            'am_au_da_fatd_2',
            'Admin state is deleted',
            'Admin user is already deleted',
            GlobalConstant::ErrorAction.default,
            {}
        ) if @delete_admin_obj.status == GlobalConstant::Admin.deleted_status

        success
      end

      # soft delete admin
      #
      # * Author: Aman
      # * Date: 03/05/2018
      # * Reviewed By:
      #
      # @return [Result::Base]
      #
      def update_admin
        @delete_admin_obj.status = GlobalConstant::Admin.deleted_status
        @delete_admin_obj.last_otp_at = nil
        @delete_admin_obj.admin_secret_id = nil
        @delete_admin_obj.password = nil
        @delete_admin_obj.save!
      end

    end

  end

end
