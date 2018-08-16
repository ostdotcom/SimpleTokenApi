module AdminManagement

  module CmsConfigurator

    class ResetEntityDraft < ServicesBase

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
      # @params [Integer] uuid (mandatory) - uuid of the admin
      #
      # @return [AdminManagement::CmsConfigurator::ResetEntityDraft]
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
            'am_cc_red_vet_1',
            'Data not found',
            'Invalid entity type',
            GlobalConstant::ErrorAction.default,
            {}
        ) if GlobalConstant::EntityGroupDraft.allowed_entity_types_from_fe.exclude?(@entity_type)

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
            'am_cc_red_red_1',
            'Invalid rquest parameters',
            'Invalid URL',
            GlobalConstant::ErrorAction.default,
            {}
        ) if (@entity_group.blank?) || (@entity_group.client_id != @client_id) || (@entity_group.uuid != @uuid)

        return error_with_data(
            'am_cc_red_red_2',
            'This draft was Active',
            'Invalid Draft Request',
            GlobalConstant::ErrorAction.default,
            {}
        ) if @entity_group.status != GlobalConstant::EntityGroup.incomplete_status

        entity_group_draft = EntityGroupDraft.where(entity_group_id: @gid, entity_type: @entity_type).first

        if entity_group_draft.blank?
          ApplicationMailer.notify(
              to: GlobalConstant::Email.default_to,
              body: 'Entitie Group draft not found for the given group id',
              data: {client_id: @client_id, admin_id: @admin_id, entity_type: @entity_type, group_id: @gid},
              subject: "Exception::Something went wrong while Get Entity Group Draft request."
          ).deliver

          return error_with_data(
              'am_cc_red_red_3',
              'No Draft is present for this admin',
              'Invalid Draft Request',
              GlobalConstant::ErrorAction.default,
              {}
          )
        end

        @entity_draft = EntityDraft.get_entity_draft_from_memcache(entity_group_draft.entity_draft_id)

        return error_with_data(
            'am_cc_red_red_4',
            'Invalid Draft Request',
            'Invalid Draft Request',
            GlobalConstant::ErrorAction.default,
            {}
        ) if @entity_draft.status == GlobalConstant::EntityDraft.deleted_status

        published_entity_groups_draft_id = PublishedEntityGroup.get_published_entity_drafts_from_memcache(@client_id)[@entity_type]

        if @entity_draft.status == GlobalConstant::EntityDraft.active_status
          return error_with_data(
              'am_cc_red_red_4',
              'This draft is already reset.',
              'IThis draft is already reset.',
              GlobalConstant::ErrorAction.default,
              {}
          ) if published_entity_groups_draft_id == @entity_draft.id

          entity_group_draft.entity_draft_id = published_entity_groups_draft_id
          entity_group_draft.save!

        else
          entity_group_draft.entity_draft_id = published_entity_groups_draft_id
          entity_group_draft.save!

          @entity_draft.status = GlobalConstant::EntityGroup.deleted_status
          @entity_draft.last_updated_admin_id = @admin_id
          @entity_draft.save!
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

        }
      end

    end

  end

end
