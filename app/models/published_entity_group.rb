class PublishedEntityGroup < EstablishSimpleTokenCustomizationDbConnection

  after_commit :memcache_flush

  # Get Key Object
  #
  # * Author: Pankaj
  # * Date: 13/08/2018
  # * Reviewed By: Aman
  #
  # @return [MemcacheKey] Key Object
  #
  def self.get_memcache_key_object
    MemcacheKey.new('customization.client_published_entity_group')
  end

  # Get/Set Active Memcache data for client published group entity drafts
  #
  # * Author: Pankaj
  # * Date: 13/08/2018
  # * Reviewed By:
  #
  # @param [Integer] id - id
  #
  # @return [Object] group_entity_drafts - All entities of group
  #
  def self.get_published_entity_drafts_from_memcache(client_id)
    memcache_key_object = PublishedEntityGroup.get_memcache_key_object
    Memcache.get_set_memcached(memcache_key_object.key_template % {client_id: client_id}, memcache_key_object.expiry) do
      self.fetch_group_entity_drafts(client_id)
    end
  end

  # Fetch group entity drafts of client
  #
  # * Author: Pankaj
  # * Date: 13/08/2018
  # * Reviewed By:
  #
  # @param [Integer] id - id
  #
  # @return [Object] group_entity_drafts - All entities of group
  #
  def self.fetch_group_entity_drafts(client_id)
    peg = PublishedEntityGroup.where(client_id: client_id).first
    entity_drafts = {}
    EntityGroupDraft.where(entity_group_id: peg.entity_group_id).all.each do |gd|
      entity_drafts[gd.entity_type] = gd.entity_draft_id
    end
    entity_drafts
  end

  # Flush Memcache
  #
  # * Author: Pankaj
  # * Date: 13/08/2018
  # * Reviewed By:
  #
  def memcache_flush
    memcache_key = EntityDraft.get_memcache_key_object.key_template % {id: self.client_id}
    Memcache.delete(memcache_key)
  end
end