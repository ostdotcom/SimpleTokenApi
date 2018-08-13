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
      #
      # @params [Integer] id (optional) - id of the entity_draft table
      # @params [String] uuid (optional) - uuid of the admin
      #
      # @return [AdminManagement::CmsConfigurator::GetThemeEntityType]
      #
      def initialize(params)
        super

        @client_id = @params[:client_id]
        @admin_id = @params[:admin_id]
        @entity_type = @params[:entity_type]
        @entity_group_id = @params[:id]
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

        r = fetch_entity_draft
        return r unless r.success?

        r = api_response
        return r unless r.success?

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

        #  todo: "KYCaas-Changes"
        # return error_with_data(
        #     'am_cc_gtet_2',
        #     'The token sale ended, it is no longer possible to submit personal information.',
        #     'The token sale ended, it is no longer possible to submit personal information.',
        #     GlobalConstant::ErrorAction.default,
        #     {},
        #     {}
        # ) if @client_settings.has_token_sale_ended?

        success
      end

      def validate_entity_type

        return error_with_data(
            'am_cc_gtet_1',
            'Data not found',
            'Invalid entity type',
            GlobalConstant::ErrorAction.default,
            {}
        ) if @entity_type.blank? || !GlobalConstant::EntityDraft.allowed_entity_types_from_fe.include?(@entity_type)

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
      def fetch_entity_draft

        if @id.present? && @uuid.present?
          puts "In IF"
          @entity_draft = EntityDraft.where(id:@id).first
          return error_with_data(
              'am_cc_gtet_2',
              'Data not found',
              'Invalid entity draft',
              GlobalConstant::ErrorAction.default,
              {}
          ) if @entity_draft.blank?

          puts "@uuid : #{@uuid} #{@uuid.class}"
          puts "@entity_draft.uuid : #{@entity_draft.uuid} #{@entity_draft.uuid.class}"

          return error_with_data(
              'am_cc_gtet_3',
              'uuid not matched with table uuid',
              'Invalid uuid',
              GlobalConstant::ErrorAction.default,
              {}
          ) if @entity_draft.uuid != @uuid.to_i

          return error_with_data(
              'am_cc_gtet_4',
              'This draft is already deleted',
              'Invalid status for getting the Entity draft',
              GlobalConstant::ErrorAction.default,
              {}
          ) if @entity_draft.status == GlobalConstant::EntityDraft.deleted_status

        else
          puts "In else"
          @entity_draft = EntityDraft.where(creator_admin_id: @admin_id,
                                           entity_type: @entity_type,
                                            status: GlobalConstant::EntityDraft.draft_status).last

          if @entity_draft.blank?
            published_entity = PublishedGroupEntity.where(client_id: @client_id).first

            if published_entity.blank?
              ApplicationMailer.notify(
                  to: GlobalConstant::Email.default_to,
                  body: error_message + published_entity.inspect,
                  data: {client_id: @client_id, creator_admin_id: @admin_id, entity_type: @entity_type},
                  subject: "Exception::Something went wrong while Get Entity Draft request."
              ).deliver
            end # send email
            entity_draft_id_from_entity_group_drafts = EntityGroupDraft.where(entity_group_id: published_entity.entity_group_id,
                                                                              entity_type: @entity_type).first

            @entity_draft = EntityDraft.where(id: entity_draft_id_from_entity_group_drafts.entity_draft_id).first
            # return exception
            return error_with_data(
                'am_cc_gtet_5',
                'Invalid request parameter',
                'Invalid request parameter',
                GlobalConstant::ErrorAction.default,
                {}
            ) if @entity_draft.status != GlobalConstant::EntityDraft.active_status
          end
        end
        #exception here if @entity_draft.blank?
        success
      end

      def api_response
        url_id = @entity_draft.id
        url_uuid = @entity_draft.uuid

        puts "@entity_type : #{@entity_type}"

        @client_settings = ClientManagement::GetClientSetting.new(client_id: @client_id).perform

        @api_response = {
            entity_config: GlobalConstant::CmsConfigurator.get_entity_config(@entity_type),
            form_data: @entity_draft.data,
            urls: {
                upload_params_url: "/api/admin/configurator/upload-params",
                current_page_url: "/admin/configurator/#{@entity_type}?id=#{url_id}&uuid=#{url_uuid}",
                reset_url: "/api/admin/configurator/reset?id=#{url_id}&uuid=#{url_uuid}",
                publish_url: "/api/admin/configurator/publish?id=#{url_id}&uuid=#{url_uuid}",
                post_url: "/api/admin/configurator/#{@entity_type}/update?id=#{url_id}&uuid=#{url_uuid}",
                accordian_config: {
                  kyc_form: {
                  id: "form",
                  preview_url: "kyc.ost.com/admin/preview?page=#{@entity_type}&id=#{url_id}&uuid=#{url_uuid}&a_accrd=form"
                  },
                  kyc_form_popup: {
                    id: "popup",
                    preview_url: "kyc.ost.com/admin/preview?page=#{@entity_type}&id=#{url_id}&uuid=#{url_uuid}&a_accrd=popup"
                  }
                }
              },
            rules: {
            can_reset: 1,
            can_publish: 1
            },
            client_settings: @client_settings
          }
        # puts "api_response : #{@api_response}"
        success
      end

    end

  end

end
