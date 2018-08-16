module AdminManagement
  module CmsConfigurator

    class UpdateEntityDraft < ServicesBase

      # Initialize
      #
      # * Author: Aniket
      # * Date: 07/08/2018
      # * Reviewed By:
      #
      # @params [Integer] client_id (mandatory) - logged in admin's client id
      # @params [Integer] admin_id (mandatory) - logged in admin's id
      # @params [String] entity_type (mandatory) - entity type
      # @params [Integer] gid (mandatory) - id of the entity_draft table
      # @params [String] uuid (mandatory) - uuid of the admin
      # @params [String] form_data (mandatory) - form data
      #
      # Sets @gid, @uuid, @entity_type, @form_data, @client_id, @admin_id
      # @return [AdminManagement::CmsConfigurator::UpdateEntityDraft]
      #
      def initialize(params)
        super
        @client_id = @params[:client_id].to_i
        @admin_id = @params[:admin_id].to_i

        @gid = @params[:gid].to_i
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
        r = validate
        return r unless r.success?

        r = fetch_and_validate_admin
        return r unless r.success?

        r = fetch_and_validate_client
        return r unless r.success?

        r = validate_entity_type
        return r unless r.success?

        r = fetch_and_validate_entity_group
        return r unless r.success?

        r = fetch_and_validate_entity_draft
        return r unless r.success?

        r = fetch_and_validate_form_data
        return r unless r.success?

        success
      end

      # Fetch and validate entity type
      #
      # * Author: Aniket
      # * Date: 16/08/2018
      # * Reviewed By:
      #
      # Sets @entity_group
      #
      def validate_entity_type

        return error_with_data(
            'am_cc_ued_vet_1',
            'Data not found',
            'Invalid entity type',
            GlobalConstant::ErrorAction.default,
            {}
        ) if GlobalConstant::EntityGroupDraft.allowed_entity_types_from_fe.exclude?(@entity_type)

        success
      end


      # Fetch and validate entity group
      #
      # * Author: Aniket
      # * Date: 16/08/2018
      # * Reviewed By:
      #
      # Sets @entity_group
      #
      def fetch_and_validate_entity_group
        @entity_group = EntityGroup.get_entity_group_from_memcache(@gid)
        if @entity_group
          error_data = {}
          error_data[:entity_group_client_id] = "client_id is not same for entity_group_id: #{@gid}" if @entity_group.client_id.to_i != @client_id
          error_data[:entity_group_uuid] = "uuid is not same for entity_group_id: #{@gid}" if @entity_group.uuid.to_s != @uuid
          error_data[:entity_group_status] = "Entity group status should be #{GlobalConstant::EntityGroup.incomplete_status}" if @entity_group.status != GlobalConstant::EntityGroup.incomplete_status

          return error_with_data(
              's_cc_ued_fave_1',
              'invalid entity params',
              "Entity group params not matching for gid: #{@gid}",
              GlobalConstant::ErrorAction.default,
              error_data
          ) if error_data.present?

          return success
        end

        return error_with_data(
            's_cc_ued_fave_2',
            'Entity group not available',
            "Entity group not available for gid: #{@gid}",
            GlobalConstant::ErrorAction.default,
            {}
        )
      end

      # Fetch and validate entity draft
      #
      # * Author: Aniket
      # * Date: 07/08/2018
      # * Reviewed By:
      #
      # Sets @entity_draft
      #
      def fetch_and_validate_entity_draft
        entity_draft_id = EntityGroupDraft.get_all_draft_ids_of_entity_group_id(@gid)[@entity_type]
        @entity_draft = EntityDraft.get_entity_draft_from_memcache(entity_draft_id)

        return error_with_data(
            's_cc_ued_fed_1',
            'Entity draft not available',
            "Entity draft not available for entity_draft_id: #{entity_draft_id}",
            GlobalConstant::ErrorAction.default,
            error_data
        ) if @entity_draft.blank?

        error_data = {}
        error_data[:entity_draft_status] = "Entity draft status is invalid for entity draft: #{entity_draft_id}" if @entity_draft.status != GlobalConstant::EntityDraft.draft_status

        return error_with_data(
            's_cc_ue_fed_2',
            'Entity group not available',
            "Entity group not available for gid: #{@gid}",
            GlobalConstant::ErrorAction.default,
            error_data
        ) if error_data.present?

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
          is_mandatory = value[GlobalConstant::CmsConfigurator.validations_key][GlobalConstant::CmsConfigurator.required_key].to_i
          form_text = @form_data[key.to_sym]
          puts form_text

          if is_mandatory == 1 && form_text.blank?
            puts "error : Mandatory_blank key: #{key}"
            error_data[key.to_sym] = "Value for #{key} should not be blank"

          elsif form_text.present?
            is_valid = Util::CmsConfigValidator.validate_cms(form_text, value)
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
            when GlobalConstant::EntityGroupDraft.kyc_form_entity_type
              GlobalConstant::CmsConfigurator.get_kyc_form_yml

            when GlobalConstant::EntityGroupDraft.dashboard_entity_type
              GlobalConstant::CmsConfigurator.get_dashboard_yml

            else
              nil
          end
        end
      end

      # Update or create entity with page data
      #
      # * Author: Aniket
      # * Date: 08/08/2018
      # * Reviewed By:
      #
      def update_entity
        @entity_draft.last_updated_admin_id = @admin_id
        @entity_draft.data = @form_data
        @entity_draft.save!

        success
      end

    end

  end
end