module AdminManagement

  module CmsConfigurator

    class GetEntityDraft < ServicesBase

      # Initialize
      #
      # * Author: Tejas
      # * Date: 08/08/2018
      # * Reviewed By:
      #
      # @params [Integer] client_id (mandatory) - logged in admin's client id
      # @params [Integer] admin_id (mandatory) - logged in admin's id
      # @params [String] entity_type (mandatory) - entity type
      # @params [Integer] gid (mandatory) - id of the entity_group table
      # @params [String] uuid (mandatory) - uuid of the admin
      #
      # @return [AdminManagement::CmsConfigurator::GetEntityDraft]
      #
      def initialize(params)
        super

        @client_id = @params[:client_id]
        @admin_id = @params[:admin_id]
        @entity_type = @params[:entity_type].to_s.strip.downcase
        @gid = @params[:gid].to_i
        @uuid = @params[:uuid]

        @client_settings = nil
        @entity_draft = nil
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

        r = fetch_entity_draft
        return r unless r.success?

        r = fetch_client_setting
        return r unless r.success?

        success_with_data(api_response)
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

        r = validate_entity_type
        return r unless r.success?

        success
      end

      # Validate Entity Type
      #
      # * Author: Tejas
      # * Date: 08/08/2018
      # * Reviewed By:
      #
      # @return [Result::Base]
      #
      def validate_entity_type

        return error_with_data(
            'am_cc_ged_vet_1',
            'Data not found',
            'Invalid entity type',
            GlobalConstant::ErrorAction.default,
            {}
        ) if GlobalConstant::EntityGroupDraft.allowed_entity_types_from_fe.exclude?(@entity_type)

        success
      end

      # Fetch Entity Draft
      #
      # * Author: Tejas
      # * Date: 08/08/2018
      # * Reviewed By:
      #
      # @return [@entity_draft]
      #
      def fetch_entity_draft

        @entity_group = EntityGroup.get_entity_group_from_memcache(@gid)

        return error_with_data(
            'am_cc_ged_fed_1',
            'Invalid rquest parameters',
            'Invalid URL',
            GlobalConstant::ErrorAction.default,
            {}
        ) if (@entity_group.blank?) || (@entity_group.client_id != @client_id) || (@entity_group.uuid != @uuid)


        return error_with_data(
            'am_cc_ged_fed_2',
            'This draft was deleted',
            'Invalid Draft Request',
            GlobalConstant::ErrorAction.default,
            {}
        ) if @entity_group.status == GlobalConstant::EntityGroup.deleted_status

        group_entities = EntityGroupDraft.get_group_entity_draft_ids_from_memcache(@gid)

        if group_entities.blank?
          ApplicationMailer.notify(
              to: GlobalConstant::Email.default_to,
              body: 'Group Entities not found for the given group id',
              data: {client_id: @client_id, admin_id: @admin_id, entity_type: @entity_type, group_id: @gid},
              subject: "Exception::Something went wrong while Get Entity Group Draft request."
          ).deliver

          return error_with_data(
              'am_cc_ged_fed_3',
              'No Draft is present for this admin',
              'Invalid Draft Request',
              GlobalConstant::ErrorAction.default,
              {}
          )
        end

        @entity_draft = EntityDraft.get_entity_draft_from_memcache(group_entities[@entity_type])

        success
      end

      # Fetch Client Setting data
      #
      # * Author: Tejas
      # * Date: 08/08/2018
      # * Reviewed By:
      #
      # @return [Hash]
      #
      def fetch_client_setting
        @client_settings = ClientManagement::GetClientSetting.new(client_id: @client_id).perform
      end

      # Api Response
      #
      # * Author: Tejas
      # * Date: 08/08/2018
      # * Reviewed By:
      #
      # @return [Hash]
      #
      def api_response

        can_reset = @entity_group.status == GlobalConstant::EntityGroup.incomplete_status ? 1 : 0
        can_publish = (@entity_group.status == GlobalConstant::EntityGroup.incomplete_status) &&
            (@admin.role == GlobalConstant::Admin.super_admin_role) ? 1 : 0

        {
            entity_config: GlobalConstant::CmsConfigurator.get_entity_config_for_fe(@entity_type, @client_settings.data),
            form_data: @entity_draft.data,
            rules: {
                can_reset: can_reset,
                can_publish: can_publish
            },
            client_settings: @client_settings.data
        }
      end

    end

  end

end