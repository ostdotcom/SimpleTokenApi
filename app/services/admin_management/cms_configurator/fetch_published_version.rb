module AdminManagement

  module CmsConfigurator

    class FetchPublishedVersion < ServicesBase

      # Initialize
      #
      # * Author: Tejas
      # * Date: 08/08/2018
      # * Reviewed By:
      #
      # @params [Integer] client_id (mandatory) - logged in admin's client id
      # @params [Integer] admin_id (mandatory) - logged in admin's id
      #
      # @return [AdminManagement::CmsConfigurator::FetchPublishedVersion]
      #
      def initialize(params)
        super

        @client_id = @params[:client_id]
        @admin_id = @params[:admin_id]

        @entity_group, @entity_draft_ids = nil, nil
        @entity_type_and_data_hash = {}
      end

      # Perform
      #
      # * Author: Tejas
      # * Date: 08/08/2018
      # * Reviewed By:
      #
      # @return [Result::Base]
      #
      def perform

        r = validate
        return r unless r.success?

        r = fetch_from_sandbox
        return r unless r.success?

        create_entity_group
        create_entity_drafts

        create_entity_group_draft
        create_published_entity_group

        success_with_data(api_response)
      end

      private

      # Validate
      #
      # * Author: Tejas
      # * Date: 14/08/2018
      # * Reviewed By:
      #
      # @return [Result::Base]
      #
      def validate
        r = super
        return r unless r.success?

        r = fetch_and_validate_client
        return r unless r.success?

        return error_with_data(
            'cm_cc_fpv_v_1',
            'Client does not have a sandbox env setup',
            'Client does not have a sandbox env setup',
            GlobalConstant::ErrorAction.default,
            {}
        ) if @client.uuid.blank?

        r = fetch_and_validate_admin
        return r unless r.success?

        success
      end

      # Fetch From Sandbox
      #
      # * Author: Tejas
      # * Date: 14/08/2018
      # * Reviewed By:
      #
      # sets @entity_type_and_data_hash
      #
      # @return [Result::Base]
      #
      def fetch_from_sandbox
        environment = Rails.env.production? ? GlobalConstant::RailsEnvironment.sandbox : Rails.env

        r = Request::SandboxApi::FetchPublishedVersion.new.perform(environment, request_data)
        return r unless r.success?

        @entity_type_and_data_hash = r.data['entity_type_and_data_hash']

        success
      end

      # Response hash
      #
      # * Author: Tejas
      # * Date: 14/08/2018
      # * Reviewed By:
      #
      # @return [Hash]
      #
      def request_data
        {uuid: @client.uuid}
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

      # create an entry in entity draft
      #
      # * Author: Aman
      # * Date: 13/08/2018
      # * Reviewed By:
      #
      # Sets @entity_draft_ids
      #
      def create_entity_drafts
        @entity_draft_ids = {}

        EntityGroupDraft.entity_types.each do |entity_type, _|
          entity_data = @entity_type_and_data_hash[entity_type].deep_symbolize_keys

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
        @entity_draft_ids.each do |entity_type, entity_draft_id|
          EntityGroupDraft.create!(entity_group_id: @entity_group.id,
                                   entity_type: entity_type,
                                   entity_draft_id: entity_draft_id)
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
        PublishedEntityGroup.where(client_id: @client_id).update(entity_group_id: @entity_group.id)
      end

      # API response
      #
      # * Author: Pankaj
      # * Date: 30/08/2018
      # * Reviewed By:
      #
      def api_response
        client_domain = ClientWebHostDetail.get_from_memcache_by_client_id(@client_id).domain
        client_domain = "https://#{client_domain}"
        {
            published_url: client_domain
        }
      end

    end

  end

end
