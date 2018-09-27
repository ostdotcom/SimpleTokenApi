module UserManagement::Users
  class List < ServicesBase

    DEFAULT_PAGE_NUMBER = 1

    # Initialize
    #
    # * Author: Aniket
    # * Date: 19/09/2018
    # * Reviewed By:
    #
    # @param [Integer] client_id (mandatory) -  client id
    # @param [Object] filter (optional) - filters for getting list
    # @param [Integer] page_number (optional ) - page number
    # @param [Integer] page_size (optional ) - page size
    # @param [String] order (optional ) - order
    #
    # Sets users_list, allowed_filters, next_page_available, total_records
    #
    # @return [UserManagement::Users::List]
    #
    def initialize(params)
      super

      @client_id = @params[:client_id]
      @filter = @params[:filter]
      @page_number = @params[:page_number]
      @order = @params[:order]
      @page_size = @params[:page_size]

      @offset = 0
      @total_records = 0
      @allowed_filters = {}

      @users_list = nil
      @is_next_page_available = false
    end

    # Perform
    #
    # * Author: Aniket
    # * Date: 19/09/2018
    # * Reviewed By:
    #
    def perform
      r = validate_and_sanitize
      return r unless r.success?

      total_numbers_of_records
      fetch_user_list

      success_with_data(service_response_data)
    end

    # private

    # Valdiate and sanitize
    #
    # * Author: Aniket
    # * Date: 19/09/2018
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
    # * Date: 19/09/2018
    # * Reviewed By:
    #
    # Sets sort_by, offset, allowed_filters
    #
    def validate_and_sanitize_params
      error_codes = []

      if @order.present?
        error_codes << 'invalid_order' unless GlobalConstant::User.sorting['sort_by'].keys.include?(@order)
      else
        @order = GlobalConstant::User.sorting['sort_by'].keys[0]
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


      @sort_by = {sort_by: @order}

      @page_size, @page_number = @page_size.to_i, @page_number.to_i

      page_size_data = GlobalConstant::PageSize.user_list
      @page_size = [@page_size, page_size_data[:min]].max
      @page_size = [@page_size, page_size_data[:max]].min

      @offset = (@page_number - 1) * @page_size

      success
    end


    # Get total number of records for particular filter.
    #
    # * Author: Aniket
    # * Date: 25/09/2018
    # * Reviewed By:
    #
    # Sets @total_records
    #
    def total_numbers_of_records
      @total_records = ar_query.count
    end

    # Fetch List of user objects
    #
    # * Author: Aniket
    # * Date: 19/09/2018
    # * Reviewed By:
    #
    # Sets users_list, next_page_available
    #
    def fetch_user_list
      @users_list = ar_query.limit(@page_size).offset(@offset).all
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
      @ar_query ||= begin
        ar = User.where(client_id: @client_id)
        ar = ar.filter_by(@allowed_filters) if @allowed_filters.present?
        ar = ar.sorting_by(@sort_by) if @sort_by.present?
        ar
      end
    end

    # Format service response
    #
    # * Author: Aniket
    # * Date: 20/09/2018
    # * Reviewed By:
    #
    def service_response_data
      {
          users: @users_list,
          meta: meta_data
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
