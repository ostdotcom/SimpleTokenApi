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
        @id = @params[:id]
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

        api_response

        success_with_data(@api_response)

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

      def validate_entity_type

        return error_with_data(
            'am_cc_pud_1',
            'Invalid entity type',
            'Invalid entity type',
            GlobalConstant::ErrorAction.default,
            {}
        ) if @entity_type.blank? || !GlobalConstant::EntityDraft.allowed_entity_types.include?(@entity_type)

        success
      end

      # Api Response
      #
      # * Author: Tejas
      # * Date: 08/08/2018
      # * Reviewed By:
      #
      # @return [Hash]
      #
      def publish_entity_draft

        if @id.present? && @uuid.present?

          @entity_draft = EntityDraft.where(id:@id, uuid:@uuid).first

          return error_with_data(
              'am_cc_rud_2',
              'Data not found',
              'Entity draft not available',
              GlobalConstant::ErrorAction.default,
              {}
          ) if @entity_draft.blank?

          return error_with_data(
              'am_cc_rud_3',
              'uuid not matched with table uuid',
              'Invalid uuid',
              GlobalConstant::ErrorAction.default,
              {}
          ) if @entity_draft.uuid != @uuid

          #verify that this validation is correct of not

          return error_with_data(
              'am_cc_gtet_4',
              'This draft is already published',
              'Invalid status for publishing the draft',
              GlobalConstant::ErrorAction.default,
              {}
          ) if @entity_draft.status != GlobalConstant::EntityDraft.draft_status

          @entity_draft.status = GlobalConstant::EntityDraft.active_status
          @entity_draft.save

          PublishedEntity.create!(
              client_id: @entity_draft.client_id,
              draft_id: @entity_draft.id,
              entity_type: @entity_draft.entity_type
          )

        end

      end

    end

  end

end
