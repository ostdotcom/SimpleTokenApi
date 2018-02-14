class PurchaseLog < EstablishSimpleTokenContractInteractionsDbConnection

  scope :of_ethereum_address, ->(ethereum_address) {where(ethereum_address: ethereum_address)}

  # Total Sales Stats
  #
  # * Author: Aman
  # * Date: 10/11/2017
  # * Reviewed By: Sunil
  #
  def self.sale_details
    memcache_key_object = MemcacheKey.new('token_sale.sale_details')
    Memcache.get_set_memcached(memcache_key_object.key_template, memcache_key_object.expiry) do
      fetch_data_for_cache
    end
  end

  # Fetch data for cache
  #
  # * Author: Aman
  # * Date: 10/11/2017
  # * Reviewed By: Sunil
  #
  def self.fetch_data_for_cache
    # return {
    #     sale_details: {
    #         total_st_token_sold: '0',
    #         total_eth_raised: '0',
    #         total_usd_value: 0,
    #         sale_ended_before_time: SaleGlobalVariable.sale_ended_flag,
    #         token_sale_active_status: GlobalConstant::TokenSale.st_token_sale_active_status
    #     }
    # } unless GlobalConstant::TokenSale.is_early_access_sale_started?

    pre_sale_data = SaleGlobalVariable.pre_sale_data

    stat_obj = PurchaseLog.select(
        'count( distinct ethereum_address) as total_unique_purchasers, ' +
            'sum(ether_wei_value) as total_ether_wei_value, sum(usd_value) ' +
            'as total_usd_value, sum(st_wei_value) as total_st_wei_value').first

    total_unique_purchasers = stat_obj.total_unique_purchasers.to_i
    total_ether_wei_value = stat_obj.total_ether_wei_value.to_i
    total_usd_value = stat_obj.total_usd_value.to_f
    total_st_wei_value = stat_obj.total_st_wei_value.to_i

    # Applies 15 % bonus for all.
    total_st_wei_value = (total_st_wei_value * 115).to_i
    total_st_wei_value = GlobalConstant::ConversionRate.divide_by_power_of_10(total_st_wei_value, 2).to_i

    total_st_wei_value += pre_sale_data[:pre_sale_st_token_in_wei_value]
    total_st_token_sold = GlobalConstant::ConversionRate.wei_to_basic_unit_in_string(total_st_wei_value)

    total_ether_wei_value += pre_sale_data[:pre_sale_eth_in_wei_value]
    total_eth_raised = GlobalConstant::ConversionRate.wei_to_basic_unit_in_string(total_ether_wei_value)

    total_usd_value += pre_sale_data[:pre_sale_usd_value]

    {
        sale_details: {
            total_st_token_sold: total_st_token_sold,
            total_eth_raised: total_eth_raised,
            total_usd_value: total_usd_value.round(2),
            total_unique_purchasers: total_unique_purchasers,
            sale_ended_before_time: SaleGlobalVariable.sale_ended_flag,
            token_sale_active_status: GlobalConstant::TokenSale.st_token_sale_active_status
        }
    }
  end

end
