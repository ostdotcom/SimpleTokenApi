class ClientAmlDetail < EstablishSimpleTokenClientDbConnection

  enum status: {
           GlobalConstant::ClientAmlDetail.active_status => 1,
           GlobalConstant::ClientAmlDetail.inactive_status => 2
       }

  after_commit :memcache_flush


  # Get Key Object
  #
  # * Author: Aman
  # * Date: 26/12/2017
  # * Reviewed By:
  #
  # @return [MemcacheKey] Key Object
  #
  def self.get_memcache_key_object
    MemcacheKey.new('client.client_aml_details')
  end

  # Get/Set Memcache data for clients aml details
  #
  # * Author: Aman
  # * Date: 26/12/2017
  # * Reviewed By:
  #
  # @param [Integer] client_id - client id
  #
  # @return [AR] ClientAmlDetail object
  #
  def self.get_from_memcache(client_id)
    memcache_key_object = ClientAmlDetail.get_memcache_key_object
    Memcache.get_set_memcached(memcache_key_object.key_template % {client_id: client_id}, memcache_key_object.expiry) do
      ClientAmlDetail.where(client_id: client_id).first
    end
  end

  private

  # Flush Memcache
  #
  # * Author: Aman
  # * Date: 26/12/2017
  # * Reviewed By:
  #
  def memcache_flush
    client_aml_details_memcache_key = ClientAmlDetail.get_memcache_key_object.key_template % {client_id: self.client_id}
    Memcache.delete(client_aml_details_memcache_key)
  end

end