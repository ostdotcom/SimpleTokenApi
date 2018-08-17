class EntityDraft < EstablishSimpleTokenCustomizationDbConnection

  serialize :data, Hash

  after_commit :memcache_flush

  enum status: {
      GlobalConstant::EntityDraft.draft_status => 1,
      GlobalConstant::EntityDraft.active_status => 2,
      GlobalConstant::EntityDraft.deleted_status => 3
  }

  # Get Key Object
  #
  # * Author: Aniket
  # * Date: 03/07/2018
  # * Reviewed By: Aman
  #
  # @return [MemcacheKey] Key Object
  #
  def self.get_memcache_key_object
    MemcacheKey.new('customization.entity_draft')
  end

  # Get/Set Active Memcache data for admin entity draft
  #
  # * Author: Aniket
  # * Date: 08/08/2018
  # * Reviewed By:
  #
  # @param [Integer] id - id
  #
  # @return [AR] EntityDraft object
  #
  def self.get_entity_draft_from_memcache(id)
    memcache_key_object = EntityDraft.get_memcache_key_object
    Memcache.get_set_memcached(memcache_key_object.key_template % {id: id}, memcache_key_object.expiry) do
      EntityDraft.where(id: id).first
    end
  end

  # Flush Memcache
  #
  # * Author: Aniket
  # * Date: 08/08/2018
  # * Reviewed By:
  #
  def memcache_flush
    admin_memcache_key = EntityDraft.get_memcache_key_object.key_template % {id: self.id}
    Memcache.delete(admin_memcache_key)
  end
end
