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
        @search = @params[:search]

        @client = nil
        @admin = nil

        @page_number = @params[:page_number].to_i || 1
        @total_filtered_users = 0
        @page_size = 10
        @users = []
        @user_kyc_details = {}
        @open_edit_cases = []
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

        fetch_users

        fetch_open_edit_kyc_cases

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

        r = fetch_and_validate_client
        return r unless r.success?

        r = fetch_and_validate_admin
        return r unless r.success?

        @filters = {} if @filters.blank? || !(@filters.is_a?(Hash) || @filters.is_a?(ActionController::Parameters))
        @sortings = {} if @sortings.blank? || !(@sortings.is_a?(Hash) || @sortings.is_a?(ActionController::Parameters))
        @search = {} if @search.blank? || !(@search.is_a?(Hash) || @search.is_a?(ActionController::Parameters)) || @search["q"].blank?

        # Validate whether filters passed are valid or not.
        @filters.each do |key, val|

          return error_with_data(
              'am_u_ul_1',
              'Invalid Parameters.',
              'Invalid Filter type passed',
              GlobalConstant::ErrorAction.default,
              {},
              {}
          ) if GlobalConstant::UserKycDetail.filters[key.to_s].blank?

          filter_data = GlobalConstant::UserKycDetail.filters[key.to_s][val.to_s]
          return error_with_data(
              'am_u_ul_2',
              'Invalid Filter Parameter value.',
              'Invalid Filter Parameter value.',
              GlobalConstant::ErrorAction.default,
              {},
              {}
          ) if filter_data.nil?
        end

        # Validate Sortings
        @sortings.each do |key, val|

          return error_with_data(
              'am_u_ul_3',
              'Invalid Parameters.',
              'Invalid Sort type passed',
              GlobalConstant::ErrorAction.default,
              {},
              {}
          ) if GlobalConstant::UserKycDetail.sorting[key.to_s].blank?

          sort_data = GlobalConstant::UserKycDetail.sorting[key.to_s][val.to_s]
          return error_with_data(
              'am_u_ul_4',
              'Invalid Sorting Parameter value.',
              'Invalid Sorting Parameter value.',
              GlobalConstant::ErrorAction.default,
              {},
              {}
          ) if sort_data.nil?
        end

        success
      end

      # Fetch users based upon filters and sortings and search term
      #
      # * Author: Pankaj
      # * Date: 15/05/2018
      # * Reviewed By:
      #
      # Sets @users, @user_kyc_details, @total_filtered_users
      #
      def fetch_users
        query = apply_kyc_submitted_filter

        # Include client_id in query
        query[0] =  query[0].present? ? "#{query[0]} AND client_id = ?" : "client_id = ?"
        query << @client_id

        # Include search term in query
        if @search["q"].present?
          query[0] += " AND email LIKE (?)"
          query << "#{@search["q"]}%"
        end

        user_relational_query = User.where(query).is_active.sorting_by(@sortings)
        offset = 0
        offset = @page_size * (@page_number - 1) if @page_number > 1
        @users = user_relational_query.limit(@page_size).offset(offset).all
        # No need to query kyc detail if filter applied is kyc_submitted_no
        if @filters["kyc_submitted"].to_s != GlobalConstant::UserKycDetail.kyc_submitted_no
          @user_kyc_details = UserKycDetail.where(user_id: @users.collect(&:id)).all.index_by(&:user_id)
        end
        @total_filtered_users = user_relational_query.count
      end

      # Make a query based on Kyc submitted filter applied
      #
      # * Author: Pankaj
      # * Date: 15/05/2018
      # * Reviewed By:
      #
      # Returns [Array] - where_clause
      #
      def apply_kyc_submitted_filter
        where_clause = []
        # If filter is applied on KYC submitted
        if [GlobalConstant::UserKycDetail.kyc_submitted_yes,
            GlobalConstant::UserKycDetail.kyc_submitted_no].include?(@filters["kyc_submitted"].to_s)

          if @filters["kyc_submitted"].to_s == GlobalConstant::UserKycDetail.kyc_submitted_no
            where_clause[0] = "properties & ? = 0"
          else
            where_clause[0] = "properties & ? > 0"
          end
          where_clause << User.properties_config[GlobalConstant::User.token_sale_kyc_submitted_property]
        end
        where_clause
      end

      # Find out edit kycs requests which are under process from given cases
      #
      # * Author: Pankaj
      # * Date: 15/05/2018
      # * Reviewed By:
      #
      # Sets @open_edit_cases
      #
      def fetch_open_edit_kyc_cases
        # No Kycs present
        return if @user_kyc_details.blank?

        case_ids = @user_kyc_details.map{|x| x[1].id}
        @open_edit_cases = EditKycRequests.under_process.where(case_id: case_ids).collect(&:case_id)
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
        users_list = []
        @users.each do |u|
          ukd_present = @user_kyc_details[u.id].present?
          users_list << {
              user_id: u.id,
              case_id: ukd_present ? @user_kyc_details[u.id].id : 0,
              email: u.email,
              registration_timestamp: u.created_at.to_i,
              kyc_submitted: ukd_present.to_i,
              whitelist_status: ukd_present ? @user_kyc_details[u.id].whitelist_status : GlobalConstant::UserKycDetail.unprocessed_whitelist_status,
              case_reopen_inprocess: (ukd_present && @open_edit_cases.include?(@user_kyc_details[u.id].id)).to_i
          }
        end

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
            users_list: users_list
        }

        @api_response_data = data

      end


    end

  end

end