module AdminManagement

  module CmsConfigurator

    class PublishUserDraft < ServicesBase

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
      # @return [AdminManagement::CmsConfigurator::PublishUserDraft]
      #
      def initialize(params)
        super

        @client_id = @params[:client_id]
        @admin_id = @params[:admin_id]
        @entity_type = @params[:entity_type]
        @gid = @params[:id]
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

        r = publish_entity_draft
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
            'am_cc_pud_vet_1',
            'Data not found',
            'Invalid entity type',
            GlobalConstant::ErrorAction.default,
            {}
        ) if GlobalConstant::EntityGroup.allowed_entity_types_from_fe.exclude?(@entity_type)

        success
      end

      # Api Response
      #
      # * Author: Tejas
      # * Date: 08/08/2018
      # * Reviewed By:
      #
      # @return [Resut::Base]
      #
      # Sets @entity_draft, @entity_group
      #
      def publish_entity_draft

        @entity_group = EntityGroup.get_entity_group_from_memcache(@gid)

        return error_with_data(
            'am_cc_pud_ped_1',
            'Invalid rquest parameters',
            'Invalid URL',
            GlobalConstant::ErrorAction.default,
            {}
        ) if (@entity_group.blank?) || (@entity_group.client_id != @client_id) || (@entity_group.uuid != @uuid)

        return error_with_data(
            'am_cc_pud_ped_2',
            'This draft was Active',
            'Invalid Draft Request',
            GlobalConstant::ErrorAction.default,
            {}
        ) if (@entity_group.status != GlobalConstant::EntityGroup.incomplete_status) &&
            (@admin.role == GlobalConstant::Admin.super_admin_role)

        entity_draft_ids_for_gid = EntityGroupDraft.get_group_entities_from_memcache(@gid).values

        ApplicationMailer.notify(
            to: GlobalConstant::Email.default_to,
            body: 'Group Entities not found for the given group id',
            data: {client_id: @client_id, admin_id: @admin_id, entity_type: @entity_type, group_id: @gid},
            subject: "Exception::Something went wrong while Get Entity Group Draft request."
        ).deliver if entity_draft_ids_for_gid.blank?

        return error_with_data(
            'am_cc_pud_ped_3',
            'No Draft is present for this admin',
            'Invalid Draft Request',
            GlobalConstant::ErrorAction.default,
            {}
        ) if entity_draft_ids_for_gid.blank?

        @entity_draft = EntityDraft.where(id: [entity_draft_ids_for_gid]).pluck("status")

        ApplicationMailer.notify(
            to: GlobalConstant::Email.default_to,
            body: 'Deleted status found for the given entity_draft_id',
            data: {client_id: @client_id, admin_id: @admin_id, last_updated_admin_id: @admin_id},
            subject: "Exception::Something went wrong while Get Entity Draft request."
        ).deliver if @entity_draft.include?("deleted")

        return error_with_data(
            'am_cc_pud_ped_4',
            'Deleted status found for the given entity_draft_id',
            'Invalid Draft Request',
            GlobalConstant::ErrorAction.default,
            {}
        ) if @entity_draft.include?("deleted")

        EntityDraft.where(id: [entity_draft_ids_for_gid]).update(status: GlobalConstant::EntityGroup.active_status)

        @entity_group.status = GlobalConstant::EntityGroup.active_status
        @entity_group.save

        PublishedEntityGroup.where(client_id: @client_id).update(entity_group_id: @gid)

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
