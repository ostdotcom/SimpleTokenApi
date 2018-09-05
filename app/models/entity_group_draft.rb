class EntityGroupDraft < EstablishSimpleTokenCustomizationDbConnection

  enum entity_type: {
      GlobalConstant::EntityGroupDraft.theme_entity_type => 1,
      GlobalConstant::EntityGroupDraft.login_entity_type => 2,
      GlobalConstant::EntityGroupDraft.registration_entity_type => 3,
      GlobalConstant::EntityGroupDraft.reset_password_entity_type => 4,
      GlobalConstant::EntityGroupDraft.change_password_entity_type => 5,
      GlobalConstant::EntityGroupDraft.token_sale_blocked_region_entity_type => 6,
      GlobalConstant::EntityGroupDraft.kyc_entity_type => 7,
      GlobalConstant::EntityGroupDraft.dashboard_entity_type => 8,
      GlobalConstant::EntityGroupDraft.verification_entity_type => 9
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
    MemcacheKey.new('customization.group_entities')
  end

  # Get/Set Active group entities from memcache for admin entity group draft
  #
  # * Author: Tejas
  # * Date: 13/08/2018
  # * Reviewed By:
  #
  # @param [Integer] entity_group_id - entity_group_id
  #
  # @return [Hash]
  #
  def self.get_group_entities_from_memcache(entity_group_id)
    memcache_key_object = EntityGroupDraft.get_memcache_key_object
    Memcache.get_set_memcached(memcache_key_object.key_template % {entity_group_id: entity_group_id}, memcache_key_object.expiry) do
      EntityGroupDraft.where(entity_group_id: entity_group_id).index_by(&:entity_type)
    end
  end

  def self.get_group_entity_draft_ids_from_memcache(entity_group_id)
    edg = get_group_entities_from_memcache(entity_group_id)
    ed_type = {}
    edg.each{|key, val| ed_type[key] = val.entity_draft_id}
    ed_type
  end

  # Flush Memcache
  #
  # * Author: Tejas
  # * Date: 13/08/2018
  # * Reviewed By:
  #
  def memcache_flush
    entity_group_draft_memcache_key = EntityGroupDraft.get_memcache_key_object.key_template % {entity_group_id: self.entity_group_id}
    Memcache.delete(entity_group_draft_memcache_key)
  end

end