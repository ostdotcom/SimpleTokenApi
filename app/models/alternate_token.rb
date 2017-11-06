class AlternateToken < EstablishSimpleTokenLogDbConnection

  enum status: {
           GlobalConstant::AlternateToken.active_status => 1,
           GlobalConstant::AlternateToken.inactive_status => 2
       }

  after_commit :memcache_flush

  # Get Key Object
  #
  # * Author: Aman
  # * Date: 06/11/2017
  # * Reviewed By: Sunil
  #
  # @return [MemcacheKey] Key Object
  #
  def self.get_memcache_key_object
    MemcacheKey.new('alternate_token.alternate_token_details')
  end

  # Get/Set Memcache data for alternate_token
  #
  # * Author: Aman
  # * Date: 06/11/2017
  # * Reviewed By: Sunil
  #
  # @param [Integer] id - alternate_token id
  #
  # @return [AR] alternate_token object
  #
  def self.get_from_memcache(id)
    memcache_key_object = AlternateToken.get_memcache_key_object
    Memcache.get_set_memcached(memcache_key_object.key_template % {id: id}, memcache_key_object.expiry) do
      AlternateToken.where(id: id).first
    end
  end

  private

  # Flush Memcache
  #
  # * Author: Aman
  # * Date: 06/11/2017
  # * Reviewed By: Sunil
  #
  def memcache_flush
    alternate_token_memcache_key = AlternateToken.get_memcache_key_object.key_template % {id: self.id}
    Memcache.delete(alternate_token_memcache_key)
  end

end