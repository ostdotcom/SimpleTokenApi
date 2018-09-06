module ClientManagement
  class GetSaleSetting < ServicesBase

    # Initialize
    #
    # * Author: Tejas
    # * Date: 27/08/2018
    # * Reviewed By:
    #
    # @param [Integer] client_id (mandatory) -  client id
    #
    # @return [ClientManagement::GetSaleSetting]
    #
    def initialize(params)
      super

      @client_id = @params[:client_id]

      @client_token_sale_detail = nil

    end

    # Perform
    #
    # * Author: Tejas
    # * Date: 27/08/2018
    # * Reviewed By:
    #
    # @return [Result::Base]
    #
    def perform

      r = validate_and_sanitize
      return r unless r.success?

      get_sale_setting

      success_with_data(success_response_data)
    end


    private

    # Validate And Sanitize
    #
    # * Author: Tejas
    # * Date: 27/08/2018
    # * Reviewed By:
    #
    #
    def validate_and_sanitize
      r = validate
      return r unless r.success?

      r = fetch_and_validate_client
      return r unless r.success?

      success
    end

    # Get Sale Setting
    #
    # * Author: Tejas
    # * Date: 27/08/2018
    # * Reviewed By:
    #
    # sets @client_token_sale_detail
    #
    def get_sale_setting
      @client_token_sale_detail = ClientTokenSaleDetail.get_from_memcache(@client_id)
    end

    # Api response data
    #
    # * Author: Tejas
    # * Date: 27/08/2018
    # * Reviewed By:
    #
    # returns [Hash] api response data
    #
    def success_response_data
      {
          sale_start_timestamp: @client_token_sale_detail.sale_start_timestamp * 1000,
          sale_end_timestamp: @client_token_sale_detail.sale_end_timestamp * 1000
      }
    end

  end
end