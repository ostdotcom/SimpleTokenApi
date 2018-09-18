class CurrentGasPrice

  MIN_GAS_PRICE = 5
  MAX_GAS_PRICE = 100
  BUFFER_GAS = 2
  DEFAULT_GAS_PRICE = 11


  # Initialize
  #
  # * Author: Pankaj
  # * Date: 18/09/2018
  # * Reviewed By:
  #
  # @return [CurrentGasPrice]
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
    gas_price = fetch_from_cache.to_i

    return DEFAULT_GAS_PRICE if gas_price <= 0

    return MIN_GAS_PRICE if gas_price < MIN_GAS_PRICE

    return MAX_GAS_PRICE if gas_price > MAX_GAS_PRICE

    gas_price
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
    gas_price = GasStationPrediction.new.perform

    return false if gas_price.ceil <= 0

    buffered_gas = gas_price.ceil + BUFFER_GAS

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
    MemcacheKey.new('general.current_gas_price')
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

end