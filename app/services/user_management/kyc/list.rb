module UserManagement
  module Kyc
    class List < ServicesBase

      DEFAULT_PAGE_NUMBER = 1

      # Initialize
      #
      # * Author: Aniket
      # * Date: 27/09/2018
      # * Reviewed By:
      #
      # @param [Integer] client_id (mandatory) -  client id
      # @param [Object] filters (optional) - filters for getting list
      # @param [Integer] page_number (optional ) - page number
      # @param [Integer] page_size (optional ) - page size
      # @param [String] order (optional ) - order
      #
      # Sets user_details_list, allowed_filters, total_records, admins
      #
      # @return [UserManagement::Kyc::List]
      #
      def initialize(params)
        super

        @client_id = @params[:client_id]
        @filters = @params[:filters]
        @page_number = @params[:page_number]
        @order = @params[:order]
        @page_size = @params[:page_size]

        @offset = 0
        @total_records = 0
        @allowed_filters = {}

        @user_kyc_details = nil
        @admins = {}
      end

      # Perform
      #
      # * Author: Aniket
      # * Date: 27/09/2018
      # * Reviewed By:
      #
      def perform
        r = validate_and_sanitize
        return r unless r.success?

        total_numbers_of_records
        fetch_user_detail_list
        fetch_admin_list

        success_with_data(service_response_data)
      end

      private

      # Valdiate and sanitize
      #
      # * Author: Aniket
      # * Date: 27/09/2018
      # * Reviewed By:
      #
      # Sets client
      #
      def validate_and_sanitize

        r = validate
        return r unless r.success?

        r = validate_and_sanitize_params
        return r unless r.success?

        r = fetch_and_validate_client
        return r unless r.success?

        success
      end

      # Validate and sanitize params
      #
      # * Author: Aniket
      # * Date: 27/09/2018
      # * Reviewed By:
      #
      # Sets sort_by, offset, allowed_filters
      #
      def validate_and_sanitize_params
        error_codes = []

        if @order.present?
          error_codes << 'invalid_order' unless GlobalConstant::UserKycDetail.sorting['order'].keys.include?(@order)
        else
          @order = GlobalConstant::UserKycDetail.sorting['order'].keys[0]
        end

        if @page_number.present?
          error_codes << 'invalid_page_number' unless Util::CommonValidateAndSanitize.is_positive_integer?(@page_number)
        else
          @page_number = DEFAULT_PAGE_NUMBER
        end

        if @page_size.present?
          error_codes << 'invalid_page_size' unless Util::CommonValidateAndSanitize.is_positive_integer?(@page_size)
        else
          @page_size = GlobalConstant::PageSize.user_list[:default]
        end

        @filters = {} if @filters.blank?

        if Util::CommonValidateAndSanitize.is_hash?(@filters)

          @filters.each do |filter_key, filter_val|
            next if filter_val.blank?
            allowed_filter = GlobalConstant::UserKycDetail.filters

            if allowed_filter.keys.include?(filter_key)
              allowed_filter_val = allowed_filter[filter_key].keys


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
                                     'um_k_l_vasp_1',
                                     error_codes
        ) if error_codes.present?

        @sort_by = {order: @order}

        @page_size, @page_number = @page_size.to_i, @page_number.to_i

        page_size_data = GlobalConstant::PageSize.user_kyc
        @page_size = [@page_size, page_size_data[:min]].max
        @page_size = [@page_size, page_size_data[:max]].min

        @offset = (@page_number - 1) * @page_size

        success
      end

      # Get total number of records for particular filter.
      #
      # * Author: Aniket
      # * Date: 27/09/2018
      # * Reviewed By:
      #
      # Sets @total_records
      #
      def total_numbers_of_records
        @total_records = ar_query.count
      end

      # Active record query for user list
      #
      # * Author: Aniket
      # * Date: 25/09/2018
      # * Reviewed By:
      #
      # returns [AR] active record object for user
      #
      def ar_query
        puts "@allowed_filters  : #{@allowed_filters}"
        @ar_query ||= begin
          ar = UserKycDetail.where(client_id: @client_id)
          ar = ar.filter_by(@allowed_filters) if @allowed_filters.present?
          ar = ar.sorting_by(@sort_by) if @sort_by.present?
          ar
        end
      end

      # Fetch user detail list
      #
      # * Author: Aniket
      # * Date: 27/09/2018
      # * Reviewed By:
      #
      # Sets @user_kyc_details
      #
      def fetch_user_detail_list
        @user_kyc_details = ar_query.limit(@page_size).offset(@offset).all
      end

      # Fetch admins list
      #
      # * Author: Aniket
      # * Date: 28/09/2018
      # * Reviewed By:
      #
      # Sets @admins
      #
      def fetch_admin_list
        @last_acted_by_ids = []
        @user_kyc_details.each do |ukd|
          @last_acted_by_ids << ukd.last_acted_by if ukd.last_acted_by.to_i > 0
        end

        return if @last_acted_by_ids.blank?
        @last_acted_by_ids.uniq!

        @admins = Admin.where(id: @last_acted_by_ids).all.index_by(&:id)
      end

      # Format service response
      #
      # * Author: Aniket
      # * Date: 27/09/2018
      # * Reviewed By:
      #
      def service_response_data
        hashed_admins = {}
        @admins.map {|id, obj| hashed_admins[id] = obj.get_hash}

        {
            user_kyc_details: @user_kyc_details.map {|x| x.get_hash},
            meta: meta_data,
            admins: hashed_admins
        }

      end

      # Format service response
      #
      # * Author: Aniket
      # * Date: 20/09/2018
      # * Reviewed By:
      #
      def meta_data
        meta_data = {total: @total_records}
        meta_data.merge!(next_page_payload: next_page_payload) if next_page_payload.present?
        meta_data
      end

      # Construct next page payload data
      #
      # * Author: Aniket
      # * Date: 20/09/2018
      # * Reviewed By:
      #
      def next_page_payload
        @next_page_payload ||= begin

          if @offset + @page_size >= @total_records
            {}
          else
            {
                page_number: @page_number + 1,
                filters: @allowed_filters,
                order: @order,
                page_size: @page_size
            }
          end

        end
      end

    end
  end
end


