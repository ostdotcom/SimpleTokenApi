module UserManagement::Users
  class List < ServicesBase

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
    # Sets users_list, next_page_payload, prev_page_payload, allowed_filters, next_page_available
    #
    # @return [UserManagement::Users::List]
    #
    def initialize(params)
      super

      @client_id = @params[:client_id]
      @filter = @params[:filter] || {}
      @page_number = @params[:page_number] || 1
      @order = @params[:order] || GlobalConstant::User.sorting['sort_by'].keys[0] # 0th index is 'desc'
      @page_size = @params[:page_size] || GlobalConstant::PageSize.user_list[:default]

      @offset = 0
      @allowed_filters = {}

      @users_list = nil
      @next_page_available = false
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

      r = fetch_and_validate_client
      return r unless r.success?

      r = validate_and_sanitize_params
      return r unless r.success?

      success
    end

    # Validate and sanitize params
    #
    # * Author: Aniket
    # * Date: 19/09/2018
    # * Reviewed By:
    #
    # Sets sorting_by, offset, allowed_filters
    #
    def validate_and_sanitize_params
      error_codes = []

      error_codes << 'invalid_order' if GlobalConstant::User.sorting['sort_by'].keys.exclude?(@order)
      error_codes << 'invalid_page_number' unless Util::CommonValidateAndSanitize.is_integer?(@page_number)
      error_codes << 'invalid_page_size' unless Util::CommonValidateAndSanitize.is_integer?(@page_size)

      return error_with_identifier('invalid_api_params',
                                   'um_u_l_vasp_1',
                                   error_codes
      ) if error_codes.present?

      @sorting_by = {sort_by: @order}

      GlobalConstant::User.allowed_filter.each do |filter|
        if @filter.include?(filter)
          @allowed_filters[filter] = @filter[filter]
        end
      end

      @page_size, @page_number = @page_size.to_i, @page_number.to_i

      page_size_data = GlobalConstant::PageSize.user_list
      @page_size = [@page_size, page_size_data[:min]].max
      @page_size = [@page_size, page_size_data[:max]].min

      @offset = (@page_number-1) * @page_size if @page_number > 0

      success
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
      @users_list = User.
                      where(client_id: @client_id).
                      filter_by(@allowed_filters).
                      limit(@page_size+1).
                      offset(@offset).
                      sorting_by(@sorting_by)

      @next_page_available = @users_list.length > @page_size

      @users_list = @users_list.reverse.drop(1).reverse if @next_page_available
      @users_list
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
      {
          next_page_payload: next_page_payload,
          payload: current_page_payload
      }
    end

    # Construct next page payload data
    #
    # * Author: Aniket
    # * Date: 20/09/2018
    # * Reviewed By:
    #
    def next_page_payload
      unless @next_page_available
        return {}
      end

      {
          page_number: @page_number+1,
          filters: @allowed_filters,
          order: @order,
      }
    end

    # Construct current page payload data
    #
    # * Author: Aniket
    # * Date: 19/09/2018
    # * Reviewed By:
    #
    def current_page_payload
      {
          page_number: @page_number,
          filters: @allowed_filters,
          order: @order,
          total_no: @users_list.length
      }
    end

  end
end
