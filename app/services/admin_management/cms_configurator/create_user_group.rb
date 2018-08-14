module AdminManagement

  module CmsConfigurator

    class CreateUserGroup < ServicesBase

      # Initialize
      #
      # * Author: Tejas
      # * Date: 08/08/2018
      # * Reviewed By:
      #
      # @params [Integer] client_id (mandatory) - logged in admin's client id
      # @params [Integer] admin_id (mandatory) - logged in admin's id
      #
      # @return [AdminManagement::CmsConfigurator::CreateUserGroup]
      #
      def initialize(params)
        super

        @client_id = @params[:client_id]
        @admin_id = @params[:admin_id]

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

        r = create_new_user_group
        return r unless r.success?

        success_with_data(success_response_data)

      end

      private

      # Validate
      #
      # * Author: Tejas
      # * Date: 08/08/2018
      # * Reviewed By:
      #
      # @return [Result::Base]
      #
      def validate
        r = super
        return r unless r.success?

        r = fetch_and_validate_client
        return r unless r.success?

        r = fetch_and_validate_admin
        return r unless r.success?

        success
      end

      # Create New User Group
      #
      # * Author: Tejas
      # * Date: 14/08/2018
      # * Reviewed By:
      #
      # @return [Resut::Base]
      #
      def create_new_user_group

        EntityGroup.create!(
            client_id: @client_id,
            uuid: Util::Encryption::Admin.get_uuid,
            creator_admin_id: @admin_id,
            status: GlobalConstant::EntityGroup.incomplete_status,
            activated_at: Time.now.to_i
        )

        entity_group_id = EntityGroup.last
        entity_type = 1
        published_entity_group_id_to_draft_id_hash = PublishedEntityGroup.get_published_entity_drafts_from_memcache(@client_id)

        EntityGroupDraft.entity_types.keys.each do |entity|

          entity_draft_id = published_entity_group_id_to_draft_id_hash[entity]

          EntityGroupDraft.create!(entity_group_id: entity_group_id.id,
                                   entity_type: entity_type,
                                   entity_draft_id: entity_draft_id
                                   )
          entity_type += 1

        end

        success
      end

      # Api response data
      #
      # * Author: Tejas
      # * Date: 14/08/2018
      # * Reviewed By:
      #
      # returns [Hash] api response data
      #
      def success_response_data
        entity_group_id = EntityGroup.last

        {
          id: entity_group_id.id,
          uuid: entity_group_id.uuid
        }
      end

    end

  end

end
