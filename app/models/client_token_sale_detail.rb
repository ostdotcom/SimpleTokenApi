class ClientTokenSaleDetail < EstablishSimpleTokenClientDbConnection

  enum status: {
           GlobalConstant::ClientTokenSaleDetail.active_status => 1,
           GlobalConstant::ClientTokenSaleDetail.inactive_status => 2
       }

  after_commit :memcache_flush


  # Token sale end time has passed
  #
  # * Author: Aman
  # * Date: 01/02/2018
  # * Reviewed By:
  #
  # @return [Boolean] return true if token sale has ended
  #
  def has_token_sale_ended?
    sale_end_timestamp <= Time.now.to_i
  end

  # Token sale start time has passed
  #
  # * Author: Aman
  # * Date: 01/02/2018
  # * Reviewed By:
  #
  # @return [Boolean] return true if token sale has started
  #
  def has_token_sale_started?
    sale_start_timestamp <= Time.now.to_i
  end

  # Token sale is live
  #
  # * Author: Aman
  # * Date: 01/02/2018
  # * Reviewed By:
  #
  # @return [Boolean] return true if token sale is live
  #
  def is_token_sale_live?
    has_token_sale_started? && !has_token_sale_ended?
  end

  # Get Key Object
  #
  # * Author: Aman
  # * Date: 01/02/2018
  # * Reviewed By:
  #
  # @return [MemcacheKey] Key Object
  #
  def self.get_memcache_key_object
    MemcacheKey.new('client.client_token_sale_details')
  end

  # Get/Set Memcache data for clients token sale details
  #
  # * Author: Aman
  # * Date: 01/02/2018
  # * Reviewed By:
  #
  # @param [Integer] client_id - client id
  #
  # @return [AR] ClientTokenSaleDetail object
  #
  def self.get_from_memcache(client_id)
    memcache_key_object = ClientTokenSaleDetail.get_memcache_key_object
    Memcache.get_set_memcached(memcache_key_object.key_template % {client_id: client_id}, memcache_key_object.expiry) do
      ClientTokenSaleDetail.where(client_id: client_id).first
    end
  end

  private

  # Flush Memcache
  #
  # * Author: Aman
  # * Date: 01/02/2018
  # * Reviewed By:
  #
  def memcache_flush
    client_token_sale_details_memcache_key = ClientTokenSaleDetail.get_memcache_key_object.key_template % {client_id: self.client_id}
    Memcache.delete(client_token_sale_details_memcache_key)
    ClientSetting.flush_memcache_key_for_template_types_of_client(self.client_id)
  end

end