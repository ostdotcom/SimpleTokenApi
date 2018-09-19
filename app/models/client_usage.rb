class ClientUsage < EstablishSimpleTokenCustomizationDbConnection

  after_commit :memcache_flush

  # Get Key Object
  #
  # * Author: Aman
  # * Date: 18/09/2018
  # * Reviewed By:
  #
  # @return [MemcacheKey] Key Object
  #
  def self.get_memcache_key_object
    MemcacheKey.new('billing.client_usage')
  end

  # Get/Set Active Memcache data for client usage
  #
  # * Author: Aman
  # * Date: 18/09/2018
  # * Reviewed By:
  #
  # @param [Integer] client_id - client_id
  #
  # @return [AR] ClientUsage object
  #
  def self.get_client_plan_from_memcache(client_id)
    memcache_key_object = ClientUsage.get_memcache_key_object
    Memcache.get_set_memcached(memcache_key_object.key_template % {client_id: client_id}, memcache_key_object.expiry) do
      ClientUsage.where(client_id: client_id).first
    end
  end

  # Flush Memcache
  #
  # * Author: Aman
  # * Date: 18/09/2018
  # * Reviewed By:
  #
  def memcache_flush
    client_usage_memcache_key = ClientUsage.get_memcache_key_object.key_template % {client_id: self.client_id}
    Memcache.delete(client_usage_memcache_key)
  end

end
