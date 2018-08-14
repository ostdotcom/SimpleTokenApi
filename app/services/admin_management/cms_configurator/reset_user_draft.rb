module AdminManagement

  module CmsConfigurator

    class ResetUserDraft < ServicesBase

      # Initialize
      #
      # * Author: Tejas
      # * Date: 08/08/2018
      # * Reviewed By:
      #
      # @params [Integer] client_id (mandatory) - logged in admin's client id
      # @params [Integer] admin_id (mandatory) - logged in admin's id
      # @params [String] entity_type (mandatory) - entity type
      # @params [Integer] id (mandatory) - id of the entity_draft table
      # @params [Integer] uuid (mandatory) - uuid of the admin
      #
      # @return [AdminManagement::CmsConfigurator::ResetUserDraft]
      #
      def initialize(params)
        super

        @client_id = @params[:client_id]
        @admin_id = @params[:admin_id]
        @entity_type = @params[:entity_type]
        @gid = @params[:gid]
        @uuid = @params[:uuid]

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

        r = reset_entity_draft
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

        r = validate_entity_type
        return r unless r.success?

        success
      end

      # Validate Entity Type
      #
      # * Author: Tejas
      # * Date: 14/08/2018
      # * Reviewed By:
      #
      # @return [Result::Base]
      #

      def validate_entity_type

        return error_with_data(
            'am_cc_rud_vet_1',
            'Data not found',
            'Invalid entity type',
            GlobalConstant::ErrorAction.default,
            {}
        ) if GlobalConstant::EntityGroup.allowed_entity_types_from_fe.exclude?(@entity_type)

        success
      end

      # Reset Entity Draft
      #
      # * Author: Tejas
      # * Date: 14/08/2018
      # * Reviewed By:
      #
      # @return [Resut::Base]
      #
      # Sets @entity_draft
      #
      def reset_entity_draft

        @entity_group = EntityGroup.get_entity_group_from_memcache(@gid)

        return error_with_data(
            'am_cc_rud_res_1',
            'Invalid rquest parameters',
            'Invalid URL',
            GlobalConstant::ErrorAction.default,
            {}
        ) if (@entity_group.blank?) || (@entity_group.client_id != @client_id) || (@entity_group.uuid != @uuid)


        return error_with_data(
            'am_cc_rud_res_2',
            'This draft was Active',
            'Invalid Draft Request',
            GlobalConstant::ErrorAction.default,
            {}
        ) if @entity_group.status != GlobalConstant::EntityGroup.incomplete_status

        group_entities = EntityGroupDraft.get_group_entities_from_memcache(@gid)

        ApplicationMailer.notify(
            to: GlobalConstant::Email.default_to,
            body: 'Group Entities not found for the given group id',
            data: {client_id: @client_id, admin_id: @admin_id, entity_type: @entity_type, group_id: @gid},
            subject: "Exception::Something went wrong while Get Entity Group Draft request."
        ).deliver if group_entities.blank?

        return error_with_data(
            'am_cc_rud_res_3',
            'No Draft is present for this admin',
            'Invalid Draft Request',
            GlobalConstant::ErrorAction.default,
            {}
        ) if group_entities.blank?

        @entity_draft = EntityDraft.get_entity_draft_from_memcache(group_entities[@entity_type])

        return error_with_data(
            'am_cc_rud_res_4',
            'This draft was Active',
            'Invalid Draft Request',
            GlobalConstant::ErrorAction.default,
            {}
        ) if @entity_draft.status != GlobalConstant::EntityDraft.draft_status

        @entity_draft.status = GlobalConstant::EntityGroup.deleted_status
        @entity_draft.save

        published_entity_groups_draft_id = PublishedEntityGroup.get_published_entity_drafts_from_memcache(@client_id)[@entity_type]
        EntityGroupDraft.where(entity_group_id: @gid, entity_type: @entity_type).update(entity_draft_id: published_entity_groups_draft_id)

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

        }
      end

    end

  end

end
