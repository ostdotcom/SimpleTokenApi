module AdminManagement

  module AdminUser

    module Invite

      class Resend < ServicesBase

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
        # @return [AdminManagement::AdminUser::Invite::Resend]
        #
        def initialize(params)
          super

          @invite_admin_id = @params[:id]
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

      end

    end
  end
end
