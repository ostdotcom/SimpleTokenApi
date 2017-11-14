class PurchaseLog < EstablishSimpleTokenContractInteractionsDbConnection

  scope :of_ethereum_address, ->(ethereum_address) { where(ethereum_address: ethereum_address) }

  # Total Sales Stats
  #
  # * Author: Aman
  # * Date: 10/11/2017
  # * Reviewed By: Sunil
  #
  def self.sale_details
    memcache_key_object = MemcacheKey.new('token_sale.sale_details')

    cache_expiry = get_sale_details_cache_expiry(memcache_key_object.expiry)

    if cache_expiry > 0
      Memcache.get_set_memcached(memcache_key_object.key_template, cache_expiry) do
        fetch_data_for_cache
      end
    else
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
    return {
        sale_details: {
            total_st_token_sold: '0',
            total_eth_raised: '0',
            total_usd_value: 0,
            sale_ended_before_time: SaleGlobalVariable.sale_ended_flag,
            token_sale_active_status: GlobalConstant::TokenSale.st_token_sale_active_status
        }
    } unless GlobalConstant::TokenSale.is_early_access_sale_started?

    pre_sale_data = SaleGlobalVariable.pre_sale_data

    stat_obj = PurchaseLog.select('sum(ether_wei_value) as total_ether_wei_value, sum(usd_value) as total_usd_value, sum(st_wei_value) as total_st_wei_value').first

    total_ether_wei_value = stat_obj.total_ether_wei_value.to_i
    total_usd_value = stat_obj.total_usd_value.to_f
    total_st_wei_value = stat_obj.total_st_wei_value.to_i

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
            sale_ended_before_time: SaleGlobalVariable.sale_ended_flag,
            token_sale_active_status: GlobalConstant::TokenSale.st_token_sale_active_status
        }
    }
  end

  # Get sale details cache expiry
  #
  # * Author: Aman
  # * Date: 10/11/2017
  # * Reviewed By: Sunil
  #
  def self.get_sale_details_cache_expiry(expiry_time)

    if !GlobalConstant::TokenSale.is_early_access_sale_started?
      calculated_time = (GlobalConstant::TokenSale.early_access_start_date.to_i - Time.now.to_i)
      calculated_time = - 1 if calculated_time <= 3
      [calculated_time, expiry_time].min
    else
      expiry_time
    end

  end

end
