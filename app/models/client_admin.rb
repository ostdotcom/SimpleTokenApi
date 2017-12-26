class ClientAdmin < EstablishSimpleTokenClientDbConnection

  enum status: {
           GlobalConstant::ClientAdmin.active_status => 1,
           GlobalConstant::ClientAdmin.inactive_status => 2
       }

  enum role: {
           GlobalConstant::ClientAdmin.normal_admin_role => 1,
           GlobalConstant::ClientAdmin.super_admin_role => 2
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
    MemcacheKey.new('client.client_admins')
  end

  # Get/Set Memcache data for clients admins
  #
  # * Author: Aman
  # * Date: 26/12/2017
  # * Reviewed By:
  #
  # @param [Integer] admin_id - admin id
  #
  # @return [AR] ClientAdmin object
  #
  def self.get_from_memcache(admin_id)
    memcache_key_object = ClientAdmin.get_memcache_key_object
    Memcache.get_set_memcached(memcache_key_object.key_template % {admin_id: admin_id}, memcache_key_object.expiry) do
      ClientAdmin.where(admin_id: admin_id).all
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
    client_admin_memcache_key = ClientAdmin.get_memcache_key_object.key_template % {admin_id: self.admin_id}
    Memcache.delete(client_admin_memcache_key)
  end

end