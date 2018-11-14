class ClientWebHostDetail < EstablishSimpleTokenClientDbConnection

  enum status: {
           GlobalConstant::ClientWebHostDetail.active_status => 1,
           GlobalConstant::ClientWebHostDetail.inactive_status => 2
       }

  after_commit :memcache_flush

  # NOTE: Deactivate consumer pages
  # mark client_web_host as inactive to stop consumer pages
  # admins can still take actions and email and other functionality will work
  # to stop admins & api calls deactivate all admins and mark client as inactive

  # Get Key Object by client id
  #
  # * Author: Aman
  # * Date: 01/02/2018
  # * Reviewed By:
  #
  # @return [MemcacheKey] Key Object
  #
  def self.get_memcache_by_client_id_key_object
    MemcacheKey.new('client.client_web_host_details_by_cid')
  end

  # Get Key Object
  #
  # * Author: Aman
  # * Date: 01/02/2018
  # * Reviewed By:
  #
  # @return [MemcacheKey] Key Object by domain
  #
  def self.get_memcache_by_domain_key_object
    MemcacheKey.new('client.client_web_host_details_by_domain')
  end

  # Get/Set Memcache data for clients host details by clien id
  #
  # * Author: Aman
  # * Date: 01/02/2018
  # * Reviewed By:
  #
  # @param [Integer] client_id - client id
  #
  # @return [AR] ClientWebHostDetail object
  #
  def self.get_from_memcache_by_client_id(client_id)
    memcache_key_object = ClientWebHostDetail.get_memcache_by_client_id_key_object
    Memcache.get_set_memcached(memcache_key_object.key_template % {client_id: client_id}, memcache_key_object.expiry) do
      ClientWebHostDetail.where(client_id: client_id).first
    end
  end

  # Get/Set Memcache data for clients host details by domain
  #
  # * Author: Aman
  # * Date: 01/02/2018
  # * Reviewed By:
  #
  # @param [String] domain - domain
  #
  # @return [AR] ClientWebHostDetail object
  #
  def self.get_from_memcache_by_domain(domain)
    memcache_key_object = ClientWebHostDetail.get_memcache_by_domain_key_object
    Memcache.get_set_memcached(memcache_key_object.key_template % {domain: domain}, memcache_key_object.expiry) do
      ClientWebHostDetail.where(domain: domain).first
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
    client_host_details_memcache_by_client_id_key = ClientWebHostDetail.get_memcache_by_client_id_key_object.key_template % {client_id: self.client_id}
    client_host_details_memcache_by_domain_key = ClientWebHostDetail.get_memcache_by_domain_key_object.key_template % {domain: self.domain}
    Memcache.delete(client_host_details_memcache_by_domain_key)
    Memcache.delete(client_host_details_memcache_by_client_id_key)
  end

end