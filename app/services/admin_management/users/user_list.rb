module AdminManagement

  module Users

    class UserList < ServicesBase

      # Initialize
      #
      # * Author: Pankaj
      # * Date: 15/05/2018
      # * Reviewed By:
      #
      # @params [String] client_id (mandatory) - this is the client id
      # @params [String] admin_id (mandatory) - this is the email entered
      #
      # @params [Hash] filters (optional)
      # @params [Hash] sortings (optional)
      #
      # @return [AdminManagement::Users::UserList]
      #
      def initialize(params)
        super

        @client_id = @params[:client_id]
        @admin_id = @params[:admin_id]

        @filters = @params[:filters]
        @sortings = @params[:sortings]

        @client = nil
        @admin = nil

        @page_number = 1
        @total_filtered_users = 0
        @page_size = 100
        @users_list = []
        @api_response_data = {}

      end

      # Perform
      #
      # * Author: Pankaj
      # * Date: 15/05/2018
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

        fetch_users

        set_api_response_data

        success_with_data(@api_response_data)

      end

      private

      # Validate and sanitize
      #
      # * Author: Pankaj
      # * Date: 15/05/2018
      # * Reviewed By:
      #
      def validate_and_sanitize
        r = validate
        return r unless r.success?

        @filters = {} if @filters.blank? || !(@filters.is_a?(Hash) || @filters.is_a?(ActionController::Parameters))
        @sortings = {} if @sortings.blank? || !(@sortings.is_a?(Hash) || @sortings.is_a?(ActionController::Parameters))

        success
      end

      # Fetch users based upon filtered
      #
      # * Author: Pankaj
      # * Date: 15/05/2018
      # * Reviewed By:
      #
      # Sets @users_list
      #
      def fetch_users
        users = User.where(client_id: @client_id).all

        users.each do |u|
          @users_list << {
              email: u.email,
              registration_timestamp: u.created_at.to_i,
              kyc_submitted: 1,
              kyc_status: GlobalConstant::UserKycDetail.kyc_approved_status
          }
        end

        @total_filtered_users = users.count
      end

      # Set API response data
      #
      # * Author: Pankaj
      # * Date: 15/05/2018
      # * Reviewed By:
      #
      # Sets @api_response_data
      #
      def set_api_response_data

        meta = {
            page_number: @page_number,
            total_records: @total_filtered_users,
            page_payload: {
            },
            page_size: @page_size,
            filters: @filters,
            sortings: @sortings,
        }

        data = {
            meta: meta,
            result_set: 'users_list',
            users_list: @users_list
        }

        @api_response_data = data

      end


    end

  end

end