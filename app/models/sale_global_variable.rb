class SaleGlobalVariable < EstablishSimpleTokenContractInteractionsDbConnection

  enum variable_kind: {
           GlobalConstant::SaleGlobalVariable.sale_ended_variable_kind => 1,
           GlobalConstant::SaleGlobalVariable.last_block_processed_variable_kind => 2,
           GlobalConstant::SaleGlobalVariable.last_block_verified_for_tokens_sold_variable_kind => 3,
           GlobalConstant::SaleGlobalVariable.pre_sale_tokens_sold_variable_kind => 4,
           GlobalConstant::SaleGlobalVariable.pre_sale_eth_received_variable_kind => 5
       }

  scope :sale_ended, -> { where(variable_kind: GlobalConstant::SaleGlobalVariable.sale_ended_variable_kind) }
  scope :last_block_processed, -> { where(variable_kind: GlobalConstant::SaleGlobalVariable.last_block_processed_variable_kind) }
  scope :last_block_verified_for_tokens_sold, -> { where(variable_kind: GlobalConstant::SaleGlobalVariable.last_block_verified_for_tokens_sold_variable_kind) }
  scope :pre_sale_data, -> { where(variable_kind: [GlobalConstant::SaleGlobalVariable.pre_sale_tokens_sold_variable_kind, GlobalConstant::SaleGlobalVariable.pre_sale_eth_received_variable_kind]) }

  after_commit :sale_variables_memcache_flush

  # fetch sale ended before time flag
  #
  # * Author: Aman
  # * Date: 31/10/2017
  # * Reviewed By: Sunil
  #
  # returns[Hash] value of sale end before time flag in db
  #
  def self.sale_ended_before_time_flag
    memcache_key_object = MemcacheKey.new('token_sale.sale_details')
    Memcache.get_set_memcached(memcache_key_object.key_template, memcache_key_object.expiry) do
      {"sale_ended_before_time" => SaleGlobalVariable.sale_ended.first.variable_data.to_i}
    end
  end

  # fetch pre sale data
  #
  # * Author: Aman
  # * Date: 10/11/2017
  # * Reviewed By:
  #
  # returns[Hash] with pre sale data
  #
  def self.pre_sale_data
    memcache_key_object = MemcacheKey.new('token_sale.pre_sale')
    Memcache.get_set_memcached(memcache_key_object.key_template, memcache_key_object.expiry) do
      objs = SaleGlobalVariable.pre_sale_data.all.index_by(&:kind)
      pre_sale_st_token_in_wei_value = objs[GlobalConstant::SaleGlobalVariable.pre_sale_tokens_sold_variable_kind].variable_data.to_i
      pre_sale_eth_in_wei_value = objs[GlobalConstant::SaleGlobalVariable.pre_sale_eth_received_variable_kind].variable_data.to_f
      pre_sale_usd_in_wei_value = GlobalConstant::ConversionRate.eth_in_wei_to_usd(pre_sale_eth_in_wei_value)

      {
          pre_sale_st_token_in_wei_value: pre_sale_st_token_in_wei_value,
          pre_sale_eth_in_wei_value: pre_sale_eth_in_wei_value,
          pre_sale_usd_in_wei_value: pre_sale_usd_in_wei_value
      }
    end
  end

  def sale_variables_memcache_flush
    memcache_key = nil
    case self.variable_kind
      when GlobalConstant::SaleGlobalVariable.sale_ended_variable_kind
        memcache_key = MemcacheKey.new('token_sale.sale_details').key_template
      when GlobalConstant::SaleGlobalVariable.pre_sale_tokens_sold_variable_kind
        memcache_key = MemcacheKey.new('token_sale.pre_sale').key_template
      when GlobalConstant::SaleGlobalVariable.pre_sale_eth_received_variable_kind
        memcache_key = MemcacheKey.new('token_sale.pre_sale').key_template
    end

    Memcache.delete(memcache_key) if memcache_key.present?
  end

end
