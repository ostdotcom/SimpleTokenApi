class EntityGroup < EstablishSimpleTokenCustomizationDbConnection

  enum status: {
      GlobalConstant::EntityGroup.incomplete_status => 1,
      GlobalConstant::EntityGroup.active_status => 2,
      GlobalConstant::EntityGroup.deleted_status => 3
  }

  after_commit :memcache_flush

  # Get Key Object
  #
  # * Author: Tejas
  # * Date: 13/08/2018
  # * Reviewed By:
  #
  # @return [MemcacheKey] Key Object
  #
  def self.get_memcache_key_object
    MemcacheKey.new('customization.entity_group')
  end

  # Get/Set Active Memcache data for admin entity group
  #
  # * Author: Tejas
  # * Date: 13/08/2018
  # * Reviewed By:
  #
  # @param [Integer] id - id
  #
  # @return [AR] EntityGroup object
  #
  def self.get_entity_group_from_memcache(id)
    memcache_key_object = EntityGroup.get_memcache_key_object
    Memcache.get_set_memcached(memcache_key_object.key_template % {id: id}, memcache_key_object.expiry) do
      EntityGroup.where(id: id).first
    end
  end

  # Flush Memcache
  #
  # * Author: Tejas
  # * Date: 13/08/2018
  # * Reviewed By:
  #
  def memcache_flush
    entity_group_memcache_key = EntityGroup.get_memcache_key_object.key_template % {id: self.id}
    Memcache.delete(entity_group_memcache_key)
  end

end