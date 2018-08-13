class EntityDraft < EstablishSimpleTokenCustomizationDbConnection

  serialize :data, Hash

  after_commit :memcache_flush

  enum entity_type: {
      GlobalConstant::EntityDraft.theme_entity_type => 1,
      GlobalConstant::EntityDraft.login_entity_type => 2,
      GlobalConstant::EntityDraft.registration_entity_type => 3,
      GlobalConstant::EntityDraft.reset_password_entity_type => 4,
      GlobalConstant::EntityDraft.change_password_entity_type => 5,
      GlobalConstant::EntityDraft.token_sale_blocked_region_entity_type => 6,
      GlobalConstant::EntityDraft.kyc_form_entity_type => 7,
      GlobalConstant::EntityDraft.dashboard_entity_type => 8,
      GlobalConstant::EntityDraft.verification_entity_type => 9
  }

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
