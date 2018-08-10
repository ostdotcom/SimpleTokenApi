module AdminManagement
  module CmsConfigurator

    class UpdateEntity < ServicesBase

      # Initialize
      #
      # * Author: Aniket
      # * Date: 07/08/2018
      # * Reviewed By:
      #
      # @params [integer] id -
      #
      # Sets @id, @uuid, @page_type, @form_data, @client_id, @admin_id
      # @return [AdminManagement::CmsConfigurator::UpdateEntity]
      #
      def initialize(params)
        super
        @client_id = @params[:client_id].to_i
        @admin_id = @params[:admin_id].to_i

        @id = @params[:id].to_i
        @uuid = @params[:uuid].to_s.strip
        @entity_type = @params[:entity_type].to_s.strip
        @form_data = @params[:form_data]

      end

      # Perform
      #
      # * Author: Aniket
      # * Date: 07/08/2018
      # * Reviewed By:
      #
      # @return [Result::Base]
      #
      def perform

        r = validate_and_sanitize
        return r unless r.success?

        r = update_entity
        return r unless r.success?

        success_with_data({})
      end

      private

      # Client, Admin, form_param validate
      #
      # * Author: Aniket/Tejas
      # * Date: 03/07/2018
      # * Reviewed By:
      #
      # Sets @admin, @client
      #
      def validate_and_sanitize
        # r = validate
        # return r unless r.success?

        # r = fetch_and_validate_admin
        # return r unless r.success?
        #
        # r = fetch_and_validate_client
        # return r unless r.success?

        r = fetch_and_validate_entity
        return r unless r.success?

        r = fetch_and_validate_form_data
        return r unless r.success?

        success
      end

      # Fetch and validate draft entity
      #
      # * Author: Aniket
      # * Date: 08/08/2018
      # * Reviewed By:
      #
      # Sets @entity
      #
      def fetch_and_validate_entity
        @entity = EntityDraft.get_entity_draft_from_memcache(@id)
        if @entity
          error_data = {}

          puts @entity.client_id.to_i, @client_id
          error_data[:uuid] = "uuid is not same for entity_id: #{@id}" if @entity.uuid.to_s != @uuid
          error_data[:entity_type] = "entity_type is not same for entity_id: #{@id}" if @entity.entity_type != @entity_type
          error_data[:client_id] = "client_id is not same for entity_id: #{@id}" if @entity.client_id.to_i != @client_id

          return error_with_data(
              's_cc_up_ue_2',
              'invalid entity params',
              "Entity not available for id: #{@id}",
              GlobalConstant::ErrorAction.default,
              error_data
          ) if error_data.present?
        end

        success
      end

      # Fetch and validate page yml
      #
      # * Author: Aniket
      # * Date: 07/08/2018
      # * Reviewed By:
      #
      # Sets @page_yml
      #
      def fetch_and_validate_form_data
        error_data = {}
        fetch_entity_type_yml

        @page_yml.each do |key, value|
          validations_mandatory = value[GlobalConstant::CmsConfigurator.validations_key][GlobalConstant::CmsConfigurator.required_key].to_i
          form_text = @form_data[key.to_sym]
          puts form_text
          if validations_mandatory == 1 && form_text.blank?
              puts "error : Mandatory_blank key: #{key}"
              error_data[key.to_sym] = "Value for #{key} should not be blank"
          elsif form_text.present?
            is_valid = Util::CmsConfigValidator.cms_validate(form_text, value)
            puts "validation result : #{is_valid} for key : #{key}"
            error_data[key.to_sym] = "Getting wrong value for #{key}" unless is_valid
          end
        end

        return error_with_data(
            's_cc_up_favfd_1',
            'Validation failed',
            "Validation failed",
            GlobalConstant::ErrorAction.default,
            error_data
        ) if error_data.present?

        success
      end

      # Fetch page yml
      #
      # * Author: Aniket
      # * Date: 07/08/2018
      # * Reviewed By:
      #
      # Sets @page_yml
      #
      def fetch_entity_type_yml
        @page_yml = begin
          case @entity_type
            when GlobalConstant::EntityDraft.kyc_form_entity_type
              GlobalConstant::CmsConfigurator.get_kyc_form_yml

            when GlobalConstant::EntityDraft.dashboard_entity_type
              GlobalConstant::CmsConfigurator.get_dashboard_yml

            when GlobalConstant::EntityDraft.dashboard_entity_type
              GlobalConstant::CmsConfigurator.get_dashboard_yml
            else
              nil
          end
        end
      end

      # Update entity with page data
      #
      # * Author: Aniket
      # * Date: 08/08/2018
      # * Reviewed By:
      #
      # Sets @page_yml
      #
      def update_entity

        if @entity && (@entity.status == GlobalConstant::EntityDraft.draft_status)
          @entity.last_updated_admin_id = @admin_id
          @entity.data = @form_data

          @entity.save!

        else
          create_entity_draft
        end

        success
      end

      # Create entity with page data
      #
      # * Author: Aniket
      # * Date: 08/08/2018
      # * Reviewed By:
      #
      # Sets @page_yml
      #
      def create_entity_draft

        draft = {
            client_id: @client_id,
            uuid: Util::Encryption::Admin.get_uuid,
            creator_admin_id: @admin_id,
            last_updated_admin_id: @admin_id,
            entity_type: @entity_type,
            data: @form_data,
            status: GlobalConstant::EntityDraft.draft_status
        }
        EntityDraft.create!(draft)
      end

    end

  end
end