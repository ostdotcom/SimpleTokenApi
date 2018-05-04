module AdminManagement

  module AdminUser

    class Dashboard < ServicesBase

      # Initialize
      #
      # * Author: Aman
      # * Date: 03/05/2018
      # * Reviewed By:
      #
      # @params [Integer] admin_id (mandatory) - logged in admin
      # @params [Integer] client_id (mandatory) - logged in admin's client id
      #
      # @return [AdminManagement::AdminUser::Dashboard]
      #
      def initialize(params)
        super

        @admin_id = @params[:admin_id]
        @client_id = @params[:client_id]

        @admin = nil
        @client = nil

        @admin_user_count = 0
        @can_invite_new_user = true

        @curr_page_data = []
        @api_response_data = {}
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
        r = validate
        return r unless r.success?

        r = fetch_and_validate_client
        return r unless r.success?

        r = fetch_and_validate_admin
        return r unless r.success?

        fetch_admins

        set_api_response_data

        success_with_data(@api_response_data)
      end

      private

      # fetch normal admins
      #
      # * Author: Aman
      # * Date: 03/05/2018
      # * Reviewed By:
      #
      # @return [Result::Base]
      #
      def fetch_admins
        admin_objs = Admin.not_deleted.where(default_client_id: @client_id).all
        admin_objs.each do |admin|
          @admin_user_count += 1
          next if admin.role != GlobalConstant::Admin.normal_admin_role
          @curr_page_data << {
              id: admin.id,
              name: admin.name,
              email: admin.email,
              status: admin.status
          }
        end

        @can_invite_new_user = (@admin_user_count >= 20) ? false : true
      end

      # Set API response data
      #
      # * Author: Aman
      # * Date: 03/05/2018
      # * Reviewed By:
      #
      # Sets @api_response_data
      #
      def set_api_response_data

        meta = {
            page_payload: {
            }
        }

        data = {
            meta: meta,
            result_set: 'admin_user_list',
            admin_user_list: @curr_page_data,
            can_invite_new_user: @can_invite_new_user.to_i
        }

        @api_response_data = data
      end


    end

  end

end
