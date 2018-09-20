module UserManagement::Users
  class List < ServicesBase

    PAGE_SIZE = 3

    # Initialize
    #
    # * Author: Aniket
    # * Date: 19/09/2018
    # * Reviewed By:
    #
    # @param [String] client_id (mandatory) -  api key of client
    # @param [Object] filter (optional) - filters for getting list
    # @param [Integer] page_number (optional ) - page number
    # @param [String] order (optional ) - order
    #
    # @Sets users_list, next_page_payload, prev_page_payload, allowed_filters, next_page_available
    #
    # @return [UserManagement::Users::List]
    #
    def initialize(params)
      super

      @client_id = @params[:client_id]
      @filter = @params[:filter] || {}
      @page_number = @params[:page_number].to_i || 1
      @order = @params[:order] || GlobalConstant::User.sorting['sort_by'].keys[0] # 0th index is 'desc'

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
    def validate_and_sanitize_params

      return error_with_data('s_sm_u_i_vp_1',
                             'Wrong value for key',
                             'Value for key order is wrong',
                             GlobalConstant::ErrorAction.default,{}
      ) unless GlobalConstant::User.sorting['sort_by'].keys.include?(@order)
      @sorting_by = {sort_by: @order}

      GlobalConstant::User.allowed_filter.each do |filter|
        if @filter.include?(filter)
          @allowed_filters[filter] = @filter[filter]
        end
      end

      @offset = (@page_number-1) * PAGE_SIZE if @page_number > 0

      success
    end

    # Fetch List of user objects
    #
    # * Author: Aniket
    # * Date: 19/09/2018
    # * Reviewed By:
    #
    def fetch_user_list
      @users_list = User.
                      filter_by(@allowed_filters).
                      limit(PAGE_SIZE+1).
                      offset(@offset).
                      sorting_by(@sorting_by)

      @next_page_available = @users_list.length > PAGE_SIZE

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
