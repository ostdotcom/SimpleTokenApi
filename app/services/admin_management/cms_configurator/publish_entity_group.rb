module AdminManagement

  module CmsConfigurator

    class PublishEntityGroup < ServicesBase

      # Initialize
      #
      # * Author: Tejas
      # * Date: 08/08/2018
      # * Reviewed By:
      #
      # @params [Integer] client_id (mandatory) - logged in admin's client id
      # @params [Integer] admin_id (mandatory) - logged in admin's id
      # @params [Integer] gid (mandatory) - id of the entity_group table
      # @params [Integer] uuid (mandatory) - uuid of the admin
      #
      # @return [AdminManagement::CmsConfigurator::PublishEntityGroup]
      #
      def initialize(params)
        super

        @client_id = @params[:client_id]
        @admin_id = @params[:admin_id]
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

        r = publish_entity_group
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

        success
      end

      # Publish Entity Group
      #
      # * Author: Tejas
      # * Date: 08/08/2018
      # * Reviewed By:
      #
      # @return [Resut::Base]
      #
      # Sets @entity_group
      #
      def publish_entity_group

        @entity_group = EntityGroup.get_entity_group_from_memcache(@gid)

        return error_with_data(
            'am_cc_peg_peg_1',
            'Invalid rquest parameters',
            'Invalid URL',
            GlobalConstant::ErrorAction.default,
            {}
        ) if (@entity_group.blank?) || (@entity_group.client_id != @client_id) || (@entity_group.uuid != @uuid)

        return error_with_data(
            'am_cc_peg_peg_2',
            'Cannot publish this group',
            'Cannot publish this group',
            GlobalConstant::ErrorAction.default,
            {}
        ) if (@entity_group.status != GlobalConstant::EntityGroup.incomplete_status)

        entity_draft_ids_for_gid = EntityGroupDraft.get_group_entity_draft_ids_from_memcache(@gid).values

        if entity_draft_ids_for_gid.blank?
          ApplicationMailer.notify(
              to: GlobalConstant::Email.default_to,
              body: 'Group Entities not found for the given group id',
              data: {client_id: @client_id, admin_id: @admin_id, group_id: @gid},
              subject: "Exception::Something went wrong while Get Entity Group Draft request."
          ).deliver

          return error_with_data(
              'am_cc_peg_peg_3',
              'No Draft is present for this admin',
              'Invalid Draft Request',
              GlobalConstant::ErrorAction.default,
              {}
          )
        end

        EntityDraft.where(id: [entity_draft_ids_for_gid]).update(status: GlobalConstant::EntityGroup.active_status, last_updated_admin_id: @admin_id)

        @entity_group.status = GlobalConstant::EntityGroup.active_status
        @entity_group.activated_at = Time.now.to_i
        @entity_group.save!

        PublishedEntityGroup.where(client_id: @client_id).update(entity_group_id: @gid)

        success

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
