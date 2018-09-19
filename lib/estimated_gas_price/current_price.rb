module EstimatedGasPrice
  class CurrentPrice


    # Initialize
    #
    # * Author: Pankaj
    # * Date: 18/09/2018
    # * Reviewed By:
    #
    # @return [EstimatedGasPrice::CurrentPrice]
    #
    def initialize

    end

    # Fetch Current gas price
    #
    # * Author: Pankaj
    # * Date: 18/09/2018
    # * Reviewed By:
    #
    # @return [Integer]
    #
    def fetch
      get_gas_price * 1000000000
    end

    # Refresh current gas price
    #
    # * Author: Pankaj
    # * Date: 18/09/2018
    # * Reviewed By:
    #
    # @return [Boolean] - Boolean value that gas price is refreshed or not
    #
    def refresh
      gas_price = EstimatedGasPrice::GasStationPrediction.new.perform

      return false if gas_price.ceil <= 0

      buffered_gas = gas_price.ceil + GlobalConstant::GasEstimations.buffer_gas

      set_in_cache(buffered_gas)

      true
    end

    private

    # Memcache key object
    #
    # * Author: Pankaj
    # * Date: 18/09/2018
    # * Reviewed By:
    #
    # @return [MemcacheKey]
    #
    def get_memcache_key_object
      MemcacheKey.new('gas_estimation.current_price')
    end

    # Fetch Gas price from cache
    #
    # * Author: Pankaj
    # * Date: 18/09/2018
    # * Reviewed By:
    #
    # @return [Integer]
    #
    def fetch_from_cache
      memcache_key_object = get_memcache_key_object

      Memcache.read(memcache_key_object.key_template)
    end

    # Set Gas Price in cache
    #
    # * Author: Pankaj
    # * Date: 18/09/2018
    # * Reviewed By:
    #
    def set_in_cache(gas_price)
      memcache_key_object = get_memcache_key_object

      Memcache.write(memcache_key_object.key_template, gas_price, memcache_key_object.expiry)
    end

    # Get Gas Price from cache and apply some validations on max and min
    #
    # * Author: Pankaj
    # * Date: 18/09/2018
    # * Reviewed By:
    #
    def get_gas_price
      gas_price = fetch_from_cache.to_i

      return GlobalConstant::GasEstimations.default_gas_price if gas_price <= 0

      return GlobalConstant::GasEstimations.min_gas_price if gas_price < GlobalConstant::GasEstimations.min_gas_price

      return GlobalConstant::GasEstimations.max_gas_price if gas_price > GlobalConstant::GasEstimations.max_gas_price

      gas_price
    end

  end
end