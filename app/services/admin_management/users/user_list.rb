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
        # pass email as filters[email] instead of search[q]
        #@order = @params[:order]
        @sortings = @params[:sortings]
        @page_number = @params[:page_number].to_i || 1
        @page_size = 10

        @client = nil
        @admin = nil

        @total_filtered_users = 0
        @users = []
        @user_kyc_details = {}
        @open_edit_cases = []
        @api_response_data = {}
        @allowed_filters = {}
        @allowed_sortings = {}

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

        error_codes = []

        if @sortings.present?
          @sortings.each do |sort_key, sort_value|
            next if sort_value.blank? || GlobalConstant::User.sorting[sort_key].blank?
            allowed_sort_values = GlobalConstant::User.sorting[sort_key].keys
            if allowed_sort_values.include?(sort_value)
              @allowed_sortings[sort_key] = sort_value
            else
              error_codes << 'invalid_sortings'
              break
            end
          end
        end

        @sortings = @allowed_sortings.present? ? @allowed_sortings : GlobalConstant::User.default_sorting

        @filters = {} if @filters.blank?

        if Util::CommonValidateAndSanitize.is_hash?(@filters)

          @filters.each do |filter_key, filter_val|
            next if filter_val.blank?

            if GlobalConstant::User.allowed_filter.include?(filter_key)
              allowed_filter_val = []

              if filter_key == GlobalConstant::User.email_filter
                allowed_filter_val = [filter_val]
              else
                allowed_filter_val = GlobalConstant::User.filters[filter_key].keys
              end

              if allowed_filter_val.include?(filter_val)
                @allowed_filters[filter_key] = filter_val.to_s
              else
                error_codes << 'invalid_filters'
              end

            end
          end

        else
          error_codes << 'invalid_filters'
        end

        error_codes.uniq!

        return error_with_identifier('invalid_api_params',
                                     'um_u_l_vasp_1',
                                     error_codes
        ) if error_codes.present?


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
        if @allowed_filters[GlobalConstant::User.is_kyc_submitted_filter].to_s != GlobalConstant::User.kyc_submitted_false
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

        user_relational_query = User.where(client_id: @client_id).is_active.filter_by(@allowed_filters)
        user_relational_query.sorting_by(@sortings)
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
            filters: @allowed_filters,
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


    end

  end

end