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
      # @params [String] search (optional)
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

        @page_number = @params[:page_number].to_i || 1
        @page_size = 10

        @client = nil
        @admin = nil

        @total_filtered_users = 0
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

          next if val.blank?

            return error_with_data(
              'am_u_ul_1',
              'Invalid Parameters.',
              'Invalid Filter type or parameter passed',
              GlobalConstant::ErrorAction.default,
              {},
              {}
          ) if page_filters[key.to_s].blank? || page_filters[key.to_s].exclude?(val.to_s)
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
          ) if GlobalConstant::User.sorting[key.to_s].blank?

          sort_data = GlobalConstant::User.sorting[key.to_s][val.to_s]
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
        user_relational_query = get_model_query
        @total_filtered_users = user_relational_query.count

        return if @total_filtered_users < 1
        offset = 0
        offset = @page_size * (@page_number - 1) if @page_number > 1
        @users = user_relational_query.limit(@page_size).offset(offset).all
        # No need to query kyc detail if filter applied is kyc_submitted_no
        if @filters["is_kyc_submitted"].to_s != kyc_submitted_no
          @user_kyc_details = UserKycDetail.where(user_id: @users.collect(&:id)).all.index_by(&:user_id)
        end
      end

      # Make a query based on Kyc submitted filter applied
      #
      # * Author: Pankaj
      # * Date: 15/05/2018
      # * Reviewed By:
      #
      # Returns [Array] - where_clause
      #
      def get_model_query
        user_relational_query = User.where(client_id: @client_id).is_active
        property_val = User.properties_config[GlobalConstant::User.token_sale_kyc_submitted_property]
        # If filter is applied on KYC submitted
        if [kyc_submitted_yes, kyc_submitted_no].include?(@filters["is_kyc_submitted"].to_s)
          if @filters["is_kyc_submitted"].to_s == kyc_submitted_no
            user_relational_query = user_relational_query.where("properties & ? = 0", property_val)
          else
            user_relational_query = user_relational_query.where("properties & ? > 0", property_val)
          end
        end

        # Include search term in query
        if @search["q"].present?
          user_relational_query = user_relational_query.where(["email LIKE (?)", "#{@search["q"].html_safe}%"])
        end

        user_relational_query = user_relational_query.sorting_by(@sortings)

        user_relational_query
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

        case_ids = @user_kyc_details.map {|x| x[1].id}
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
          ukd = @user_kyc_details[u.id]
          ukd_present = ukd.present?
          users_list << {
              user_id: u.id,
              case_id: ukd_present ? @user_kyc_details[u.id].id : 0,
              email: u.email,
              registration_timestamp: u.created_at.to_i,
              is_kyc_submitted: ukd_present.to_i,
              whitelist_status: ukd_present ? @user_kyc_details[u.id].whitelist_status : nil,
              action_to_perform: action_to_perform(ukd)
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

      # IF reopen case request can be sent for this user
      #
      # * Author: Aman
      # * Date: 15/05/2018
      # * Reviewed By:
      #
      # Returns[Boolean] - True/False
      #
      def can_delete?(user_kyc_detail)
        return true if user_kyc_detail.blank? || user_kyc_detail.can_delete?
        return false
      end

      # Actions under process
      #
      # * Author: Pankaj
      # * Date: 15/05/2018
      # * Reviewed By:
      #
      # Returns[Array] - keys of action under process
      #
      def action_under_process(user_kyc_detail)
        return [] if can_delete?(user_kyc_detail)
        data = []
        data << "case_reopen_inprocess" if @open_edit_cases.include?(user_kyc_detail.id)
        data << "whitelist_confirmation_pending" if @client.is_whitelist_setup_done? && user_kyc_detail.kyc_approved? && !user_kyc_detail.whitelist_confirmation_done?
        return data
      end

      # IF reopen case request can be sent for this user
      #
      # * Author: Aman
      # * Date: 15/05/2018
      # * Reviewed By:
      #
      # Returns[Boolean] - True/False
      #
      def can_reopen_case?(user_kyc_detail)
        return false if can_delete?(user_kyc_detail) || action_under_process(user_kyc_detail).present?
        return true
      end

      # IF reopen case request can be sent for this user
      #
      # * Author: Aman
      # * Date: 15/05/2018
      # * Reviewed By:
      #
      # Returns[Array] - Action to perform for this user
      #
      def action_to_perform(user_kyc_detail)
        data = []
        if can_delete?(user_kyc_detail)
          data << "delete"
          return data
        end

        if can_reopen_case?(user_kyc_detail)
          data << "reopen"
          return data
        end

        data += action_under_process(user_kyc_detail)
        data
      end

      # Filters which can be allowed on this page
      #
      def page_filters
        @page_filters ||= {
            "is_kyc_submitted" => [kyc_submitted_yes, kyc_submitted_no]
        }
      end

      # ### KYC Submitted Filter options ###
      def kyc_submitted_yes
        'yes'
      end

      def kyc_submitted_no
        'no'
      end

      # ### KYC Submitted Filter options ###

    end

  end

end