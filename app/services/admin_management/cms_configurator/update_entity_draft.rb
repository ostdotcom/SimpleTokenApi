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

        fetch_entity_draft
        fetch_entity_group_draft

        r = update_entity_draft
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

          if (@entity_group.client_id.to_i != @client_id ||
              @entity_group.uuid.to_s != @uuid ||
              @entity_group.status != GlobalConstant::EntityGroup.incomplete_status)

            return error_with_data(
                's_cc_ued_fave_1',
                'invalid entity params',
                "Params not matching for gid: #{@gid}",
                GlobalConstant::ErrorAction.default,
                {}
            )
          end

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

      # Fetch and validate page yml
      #
      # * Author: Aniket
      # * Date: 07/08/2018
      # * Reviewed By:
      #
      def fetch_and_validate_form_data
        error_data = {}
        @page_yml = GlobalConstant::CmsConfigurator.get_entity_config(@entity_type)

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

      # Fetch entity group draft
      #
      # * Author: Aniket
      # * Date: 17/08/2018
      # * Reviewed By:
      #
      # Sets @entity_draft
      #
      def fetch_entity_group_draft
        @entity_group_draft = EntityGroupDraft.get_group_entities_from_memcache(@gid)[@entity_type]
      end

      # Fetch entity draft
      #
      # * Author: Aniket
      # * Date: 07/08/2018
      # * Reviewed By:
      #
      # Sets @entity_draft
      #
      def fetch_entity_draft
        @entity_draft = EntityDraft.get_entity_draft_from_memcache(@entity_group_draft.entity_draft_id)
      end

      # Update or create entity draft with page data
      #
      # * Author: Aniket
      # * Date: 08/08/2018
      # * Reviewed By:
      #
      def update_entity_draft
        if @entity_draft.status == GlobalConstant::EntityDraft.active_status
          create_entity_draft
          update_entity_group_draft
        else
          @entity_draft.last_updated_admin_id = @admin_id
          @entity_draft.data = @form_data
          @entity_draft.save!
        end

        success
      end

      # Create entity draft with page data
      #
      # * Author: Aniket
      # * Date: 17/08/2018
      # * Reviewed By:
      #
      def create_entity_draft
        params = {
            client_id: @client_id,
            last_updated_admin_id: @admin_id,
            data: @form_data,
            status: GlobalConstant::EntityDraft.draft_status
        }

        @entity_draft = EntityDraft.create!(params)

      end

      # Update entity group draft with page data
      #
      # * Author: Aniket
      # * Date: 17/08/2018
      # * Reviewed By:
      #
      def update_entity_group_draft
        @entity_group_draft.entity_draft_id = @entity_draft.id
        @entity_group_draft.save! if @entity_group_draft.changed?
      end

    end

  end
end