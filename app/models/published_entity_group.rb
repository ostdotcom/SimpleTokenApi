class PublishedEntityGroup < EstablishSimpleTokenCustomizationDbConnection

  after_commit :clear_client_settings_cache

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
  def self.fetch_published_draft_ids(client_id)
    peg = PublishedEntityGroup.where(client_id: client_id).first
    entity_drafts = {}
    EntityGroupDraft.where(entity_group_id: peg.entity_group_id).all.each do |gd|
      entity_drafts[gd.entity_type] = gd.entity_draft_id
    end
    entity_drafts
  end

  # Flush client settings Memcache
  #
  # * Author: Pankaj
  # * Date: 13/08/2018
  # * Reviewed By:
  #
  def clear_client_settings_cache
    ClientSetting.flush_client_settings_cache(self.client_id)
  end
end