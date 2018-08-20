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
        @entity_type = @params[:entity_type].to_s.strip.downcase

        # Note: @form_data includes all params data(client_id, admin_id , controller etc)
        @form_data = @params[:form_data]

        @entity_group, @entity_group_draft, @entity_draft = nil, nil, nil
        @client_settings = nil
        @store_data = {}
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

        fetch_entity_group_draft
        fetch_entity_draft

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

        return error_with_data(
            's_cc_ued_fave_1',
            'Entity group not available',
            "Entity group not available for gid: #{@gid}",
            GlobalConstant::ErrorAction.default,
            {}
        ) if @entity_group.blank?

        return error_with_data(
            's_cc_ued_fave_2',
            'invalid entity params',
            "Invalid Request",
            GlobalConstant::ErrorAction.default,
            {}
        ) if (@entity_group.client_id.to_i != @client_id || @entity_group.uuid.to_s != @uuid ||
            @entity_group.status == GlobalConstant::EntityGroup.deleted_status)

        return error_with_data(
            's_cc_ued_fave_3',
            'invalid entity params',
            "This version has already been published and cannot be updated",
            GlobalConstant::ErrorAction.default,
            {}
        ) if @entity_group.status != GlobalConstant::EntityGroup.incomplete_status

        success
      end

      # Fetch and validate page yml
      #
      # * Author: Aniket
      # * Date: 07/08/2018
      # * Reviewed By:
      #
      def fetch_and_validate_form_data
        error_data = {}
        entity_config = fetch_entity_config_for_fe

        entity_config.each do |key, entity_config|
          next if entity_config[GlobalConstant::CmsConfigurator.not_eligible_key].to_i == 1

          entity_error_data = {}

          entity_val = @form_data[key.to_sym]
          puts entity_val

          # max_length, min_length, required, includes
          entity_validations = entity_config[GlobalConstant::CmsConfigurator.validations_key]
          data_kind = entity_config[GlobalConstant::CmsConfigurator.data_kind_key]
          is_mandatory = entity_validations[GlobalConstant::CmsConfigurator.required_key].to_i

          error_key = key.to_sym

          if is_mandatory == 1 && entity_val.blank?
            puts "error : Mandatory_blank key: #{key}"
            entity_error_data[error_key] = "This field cannot be blank"
          elsif entity_val.present?
            if data_kind == GlobalConstant::CmsConfigurator.value_array
              err_msg = basic_validations(entity_val, entity_validations)
              if err_msg.present?
                entity_error_data[error_key] = err_msg
                # make it blank so no other validation on element level is performed
                entity_val = []
              end

              element_config = entity_config[GlobalConstant::CmsConfigurator.element_key]
              element_data_kind = element_config[GlobalConstant::CmsConfigurator.data_kind_key]
              element_validations = element_config[GlobalConstant::CmsConfigurator.validations_key]

              entity_val.each_with_index do |element_val, index|
                err_msg = validate_element(element_val, element_data_kind, element_validations)
                entity_error_data["#{error_key.to_s}[#{index}]".to_sym] = err_msg if err_msg.present?
              end

            else
              err_msg = validate_element(entity_val, data_kind, entity_validations)
              entity_error_data[error_key] = err_msg if err_msg.present?
            end
          end

          if entity_error_data.blank?
            @store_data[key.to_sym] = entity_val
          else
            error_data.merge!(entity_error_data)
          end
        end

        case @entity_type
          when GlobalConstant::EntityGroupDraft.theme_entity_type
            theme_error_data = theme_related_validations
            error_data.reverse_merge!(theme_error_data) if theme_error_data.present?
            break

            key = GlobalConstant::CmsConfigurator.company_logo_key
            @store_data[key.to_sym] = cloudfront_domain + @store_data[key.to_sym].to_s

            key = GlobalConstant::CmsConfigurator.company_favicon_key
            company_favicon = @store_data[key]
            @store_data[key.to_sym] = cloudfront_domain + @store_data[key.to_sym].to_s if company_favicon.present?
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

      def validate_element(entity_val, data_kind, entity_validations)
        err_msg = basic_validations(entity_val, entity_validations)
        return err_msg if err_msg.present?

        case data_kind
          when GlobalConstant::CmsConfigurator.value_color
            Util::CmsConfigValidator.validate_color(entity_val)
          when GlobalConstant::CmsConfigurator.value_text
            Util::CmsConfigValidator.validate_text(entity_val)
          when GlobalConstant::CmsConfigurator.value_html
            Util::CmsConfigValidator.validate_html(entity_val)
          when GlobalConstant::CmsConfigurator.value_number
            Util::CmsConfigValidator.validate_number(entity_val)
          when GlobalConstant::CmsConfigurator.value_link
            Util::CmsConfigValidator.validate_url(entity_val)
          when GlobalConstant::CmsConfigurator.value_gradient
            return 'Invalid Gradient option' if !entity_val.is_a?(Hash)

            color = entity_val[GlobalConstant::CmsConfigurator.value_color]
            err_msg_color = Util::CmsConfigValidator.validate_color(color)
            return err_msg_color if err_msg_color.present?

            gradient = entity_val[GlobalConstant::CmsConfigurator.value_gradient]
            err_msg_gradient = Util::CmsConfigValidator.validate_number(gradient)
            err_msg_gradient
          else
            fail "Invalid Data kind - #{data_kind}"
        end
      end


      def basic_validations(entity_value, validations)
        if entity_value.is_a?(Array)
          max_count = validations[GlobalConstant::CmsConfigurator.max_count_key]
          return "Entities cannot be more than #{max_count}" if max_count && entity_value.length > max_count

          min_count = validations[GlobalConstant::CmsConfigurator.min_count_key]
          return "Entities cannot be less than #{min_count}" if min_count && entity_value.length < min_count
        else
          max_length = validations[GlobalConstant::CmsConfigurator.max_length_key]
          return "Length cannot be more than #{max_length}" if max_length && entity_value.length > max_length

          min_length = validations[GlobalConstant::CmsConfigurator.min_length_key]
          return "Length cannot be less than #{min_length}" if min_length && entity_value.length < min_length
        end

        includes_validation = validations[GlobalConstant::CmsConfigurator.includes_key]
        return "Entered Value is not allowed" if includes_validation && includes_validation.exclude?(entity_value)

        return nil
      end

      # Validate theme related config.
      #
      # * Author: Aniket
      # * Date: 20/08/2018
      # * Reviewed By:
      #
      def theme_related_validations
        # todo logo full url
        theme_error_data = {}

        company_logo = @form_data[GlobalConstant::CmsConfigurator.company_logo_key]

        theme_error_data[GlobalConstant::CmsConfigurator.company_logo_key.to_sym] = "Wrong company logo URL." if company_logo.match(AdminManagement::CmsConfigurator::GetUploadParams::CLIENT_ASSET_FILE_PATH_REGEX).blank?

        company_favicon = @form_data[GlobalConstant::CmsConfigurator.company_favicon_key]

        if company_favicon.present?
          theme_error_data[GlobalConstant::CmsConfigurator.company_favicon_key.to_sym] = "Wrong company favicon URL." if company_favicon.match(AdminManagement::CmsConfigurator::GetUploadParams::CLIENT_ASSET_FILE_PATH_REGEX).blank?
        end

        theme_error_data
      end

      # Fetch entity config
      #
      # * Author: Aniket
      # * Date: 17/08/2018
      # * Reviewed By:
      #
      def fetch_entity_config_for_fe
        @client_settings = ClientManagement::GetClientSetting.new({client_id: @client_id}).perform

        GlobalConstant::CmsConfigurator.get_entity_config_for_fe(@entity_type, @client_settings.data)
      end

      # Fetch entity group draft
      #
      # * Author: Aniket
      # * Date: 17/08/2018
      # * Reviewed By:
      #
      # Sets @entity_group_draft
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
        @entity_draft = EntityDraft.get_entity_draft_from_memcache(@entity_group_draft[:entity_draft_id])
      end

      # Update or create entity draft with page data
      #
      # * Author: Aniket
      # * Date: 08/08/2018
      # * Reviewed By:
      #
      def update_entity_draft
        if @entity_draft.status != GlobalConstant::EntityDraft.draft_status
          create_entity_draft
          update_entity_group_draft
        else
          @entity_draft.last_updated_admin_id = @admin_id
          @entity_draft.data = @store_data
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
            data: @store_data,
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