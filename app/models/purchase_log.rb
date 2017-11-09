class PurchaseLog < EstablishSimpleTokenContractInteractionsDbConnection


  def self.total_purchase_details
    memcache_key_object = MemcacheKey.new('token_sale.total_sale')
    Memcache.get_set_memcached(memcache_key_object.key_template, memcache_key_object.expiry) do
      pre_sale_data = SaleGlobalVariable.pre_sale_data

      PurchaseLog.select('sum(ether_wei_value) as total_ether_wei_value, sum(usd_value) as total_usd_value, sum(st_wei_value) as total_st_wei_value').first.total_tokens_in_wei_sold.to_i

      total_st_wei_value += pre_sale_data[:pre_sale_st_token_in_wei_value]
      pre_sale_st_token_value = GlobalConstant::ConversionRate.wei_to_basic_unit(total_st_wei_value)

      total_ether_wei_value += pre_sale_data[:pre_sale_eth_in_wei_value]
      pre_sale_eth_value = GlobalConstant::ConversionRate.wei_to_basic_unit(total_ether_wei_value)

      total_usd_value += pre_sale_data[:pre_sale_usd_value]

      {
          pre_sale_st_token_value: pre_sale_st_token_value,
          pre_sale_eth_value: pre_sale_eth_value,
          pre_sale_usd_value: pre_sale_usd_value
      }
    end
  end


end
