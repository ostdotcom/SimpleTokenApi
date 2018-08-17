module AdminManagement

  module CmsConfigurator

    class CreateEntityGroup < ServicesBase

      # Initialize
      #
      # * Author: Tejas
      # * Date: 14/08/2018
      # * Reviewed By:
      #
      # @params [Integer] client_id (mandatory) - logged in admin's client id
      # @params [Integer] admin_id (mandatory) - logged in admin's id
      #
      # @return [AdminManagement::CmsConfigurator::CreateEntityGroup]
      #
      def initialize(params)
        super

        @client_id = @params[:client_id]
        @admin_id = @params[:admin_id]

        @entity_group = nil
      end

      # Perform
      #
      # * Author: Tejas
      # * Date: 14/08/2018
      # * Reviewed By:
      #
      # @return [Result::Base]
      #
      def perform

        r = validate
        return r unless r.success?

        r = create_entity_group
        return r unless r.success?

        success_with_data(success_response_data)

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

        r = fetch_and_validate_admin
        return r unless r.success?

        r = validate_client_web_host
        return r unless r.success?

        success
      end

      # Validate Client Web Host
      #
      # * Author: Tejas
      # * Date: 14/08/2018
      # * Reviewed By:
      #
      # @return [Result::Base]
      #
      def validate_client_web_host
        return error_with_data(
            'am_cc_ceg_vcwh_1',
            'This client dose not have web_host setup.',
            'This client dose not have web_host setup.',
            GlobalConstant::ErrorAction.default,
            {}
        ) if !@client.is_web_host_setup_done?
        success
      end

      # Create Entity Group
      #
      # * Author: Tejas
      # * Date: 14/08/2018
      # * Reviewed By:
      #
      # sets @entity_group
      #
      # @return [Resut::Base]
      #
      def create_entity_group

        @entity_group = EntityGroup.create!(
            client_id: @client_id,
            uuid: Util::Encryption::Admin.get_uuid,
            creator_admin_id: @admin_id,
            status: GlobalConstant::EntityGroup.incomplete_status
        )

        published_entity_group_id_to_draft_id_hash = PublishedEntityGroup.fetch_published_draft_ids(@client_id)

        published_entity_group_id_to_draft_id_hash.each do |entity_type, draft_id|

          EntityGroupDraft.create!(entity_group_id: @entity_group.id,
                                   entity_type: entity_type,
                                   entity_draft_id: draft_id
                                   )

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
        {
          gid: @entity_group.id,
          uuid: @entity_group.uuid
        }
      end

    end

  end

end
