class PurchaseLog < EstablishSimpleTokenContractInteractionsDbConnection

  after_commit :memcache_flush

  def self.total_purchase_details
    memcache_key_object = MemcacheKey.new('token_sale.total_sale')
    Memcache.get_set_memcached(memcache_key_object.key_template, memcache_key_object.expiry) do
      pre_sale_data = SaleGlobalVariable.pre_sale_data

      stat_obj = PurchaseLog.select('sum(ether_wei_value) as total_ether_wei_value, sum(usd_value) as total_usd_value, sum(st_wei_value) as total_st_wei_value').first

      total_st_wei_value = stat_obj.total_st_wei_value + pre_sale_data[:pre_sale_st_token_in_wei_value]
      total_st_token_value = GlobalConstant::ConversionRate.wei_to_basic_unit(total_st_wei_value)

      total_ether_wei_value = stat_obj.total_ether_wei_value + pre_sale_data[:pre_sale_eth_in_wei_value]
      total_eth_value = GlobalConstant::ConversionRate.wei_to_basic_unit(total_ether_wei_value)

      total_usd_value = stat_obj.total_usd_value + pre_sale_data[:pre_sale_usd_value]

      {
          total_st_token_value: total_st_token_value,
          total_eth_value: total_eth_value,
          total_usd_value: total_usd_value
      }
    end

  end

  # Flush Memcache
  #
  # * Author: Aman
  # * Date: 10/11/2017
  # * Reviewed By:
  #
  def memcache_flush
    memcache_key = MemcacheKey.new('token_sale.total_sale').key_template
    Memcache.delete(memcache_key)
  end

end
