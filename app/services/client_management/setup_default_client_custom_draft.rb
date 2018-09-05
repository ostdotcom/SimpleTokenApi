module ClientManagement
  class SetupDefaultClientCustomDraft < ServicesBase

    # Initialize
    #
    # * Author: Aniket
    # * Date: 04/07/2018
    # * Reviewed By:
    #
    # @param [Integer] admin_id (mandatory) -  admin id
    # @param [Integer] client_id (mandatory) -  client id
    #
    # @return [ClientManagement::SetupDefaultClientCustomDraft]
    #
    def initialize(params)
      super
      @client_id = @params[:client_id]
      @admin_id = @params[:admin_id]

      @entity_group, @entity_draft_ids = nil, nil
    end

    # Perform
    #
    # * Author: Aman
    # * Date: 13/08/2018
    # * Reviewed By:
    #
    # @return [Result::Base]
    #
    def perform
      r = validate_and_sanitize
      return r unless r.success?

      create_entity_group
      create_entity_drafts

      create_entity_group_draft
      create_published_entity_group

      success
    end


    private

    # Validate And Sanitize
    #
    # * Author: Aman
    # * Date: 13/08/2018
    # * Reviewed By:
    #
    # Sets @client, @admin
    #
    def validate_and_sanitize
      r = validate
      return r unless r.success?

      r = fetch_and_validate_client
      return r unless r.success?

      r = fetch_and_validate_admin
      return r unless r.success?

      success
    end

    # create an entry in entity group
    #
    # * Author: Aman
    # * Date: 13/08/2018
    # * Reviewed By:
    #
    # Sets @entity_group
    #
    def create_entity_group
      @entity_group = EntityGroup.create!(client_id: @client_id,
                                          uuid: Util::Encryption::Admin.get_uuid,
                                          creator_admin_id: @admin_id,
                                          status: GlobalConstant::EntityGroup.active_status,
                                          activated_at: Time.now.to_i)
    end

    # create an entry in entity group
    #
    # * Author: Aman
    # * Date: 13/08/2018
    # * Reviewed By:
    #
    # Sets @entity_draft_ids
    #
    def create_entity_drafts
      @entity_draft_ids = {}
      @default_template_data = GlobalConstant::CmsConfigurator.custom_default_template_data

      EntityGroupDraft.entity_types.each do |entity_type, _|
        entity_data = @default_template_data[entity_type.to_s] || {}
        obj = EntityDraft.create!(client_id: @client_id,
                                  last_updated_admin_id: @admin_id,
                                  data: entity_data,
                                  status: GlobalConstant::EntityDraft.active_status)
        @entity_draft_ids[entity_type] = obj.id
      end
    end

    # create all entity group draft
    #
    # * Author: Aman
    # * Date: 13/08/2018
    # * Reviewed By:
    #
    #
    def create_entity_group_draft
      @entity_draft_ids.each do |entity_type, draft_id|
        EntityGroupDraft.create!(entity_group_id: @entity_group.id,
                                 entity_type: entity_type,
                                 entity_draft_id: draft_id)
      end

    end

    # create all entity group draft
    #
    # * Author: Aman
    # * Date: 13/08/2018
    # * Reviewed By:
    #
    #
    def create_published_entity_group
      PublishedEntityGroup.create!(client_id: @client_id, entity_group_id: @entity_group.id)
    end

  end
end


