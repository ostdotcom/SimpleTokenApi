class SaleGlobalVariable < EstablishSimpleTokenContractInteractionsDbConnection

  enum variable_kind: {
           GlobalConstant::SaleGlobalVariable.sale_ended_variable_kind => 1,
           GlobalConstant::SaleGlobalVariable.last_block_processed_variable_kind => 2
       }

  scope :sale_ended, -> { where(variable_kind: GlobalConstant::SaleGlobalVariable.sale_ended_variable_kind) }
  scope :last_block_processed, -> { where(variable_kind: GlobalConstant::SaleGlobalVariable.last_block_processed_variable_kind) }

  after_commit :sale_ended_memcache_flush

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

  def sale_ended_memcache_flush
    return if self.variable_kind != sale_ended_variable_kind
    memcache_key = MemcacheKey.new('token_sale.sale_details').key_template
    Memcache.delete(memcache_key)
  end

end
