module SaleManagement

  class GetDetails < ServicesBase

    # Initialize
    #
    # * Author: Aman
    # * Date: 31/10/2017
    # * Reviewed By:
    #
    # @return [SaleManagement::GetDetails]
    #
    def initialize(params)
      super

      @sale_ended_before_time = false
    end

    # Perform
    #
    # * Author: Aman
    # * Date: 31/10/2017
    # * Reviewed By:
    #
    # @return [Result::Base]
    #
    def perform
      fetch_details
      set_memcache
      success_with_data(api_response_data)
    end

    private

    # fetch sale details
    #
    # * Author: Aman
    # * Date: 31/10/2017
    # * Reviewed By:
    #
    # Sets[@sale_ended_before_time]
    #
    def fetch_details
      @sale_ended_before_time = SaleGlobalVariable.sale_ended.first.to_i
    end

    # Set memcache
    #
    # * Author: Aman
    # * Date: 31/10/2017
    # * Reviewed By:
    #
    # Sets memcache data
    #
    def set_memcache
      memcache_key_object = MemcacheKey.new('token_sale.sale_details')
      Memcache.write(memcache_key_object.key_template, api_response_data, memcache_key_object.expiry)
    end

    # Api Response data
    #
    # * Author: Aman
    # * Date: 31/10/2017
    # * Reviewed By:
    #
    # Sets[@sale_ended_before_time]
    #
    def api_response_data
      {
          sale_ended_before_time: @sale_ended_before_time
      }
    end

  end

end
