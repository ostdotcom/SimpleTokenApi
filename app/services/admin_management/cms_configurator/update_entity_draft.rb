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

        get_response_data
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

          entity_val = JSON.parse(@form_data[key.to_sym].to_json)

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
              entity_val, err_msg = basic_validations(entity_val, data_kind, entity_validations)
              if err_msg.present?
                entity_error_data[error_key] = err_msg
                # make it blank so no other validation on element level is performed
                entity_val = []
              end

              element_config = entity_config[GlobalConstant::CmsConfigurator.element_key]
              element_data_kind = element_config[GlobalConstant::CmsConfigurator.data_kind_key]
              element_validations = element_config[GlobalConstant::CmsConfigurator.validations_key]

              entity_val.each_with_index do |element_val, index|
                entity_val, err_msg = validate_element(element_val, element_data_kind, element_validations)
                entity_error_data["#{error_key.to_s}[#{index}]".to_sym] = err_msg if err_msg.present?
              end

            else
              entity_val, err_msg = validate_element(entity_val, data_kind, entity_validations)
              entity_error_data[error_key] = err_msg if err_msg.present?
            end
          end

          if entity_error_data.blank?
            @store_data[key.to_sym] = entity_val
          else
            error_data.merge!(entity_error_data)
          end
        end

        error_data.reverse_merge!(validate_uploaded_files_path)

        return error_with_data(
            's_cc_up_favfd_1',
            'Validation failed',
            "Validation failed",
            GlobalConstant::ErrorAction.default,
            {},
            error_data
        ) if error_data.present?

        success
      end

      def validate_element(entity_val, data_kind, entity_validations)
        entity_val, err_msg = basic_validations(entity_val, data_kind, entity_validations)
        return err_msg if err_msg.present?

        case data_kind
          when GlobalConstant::CmsConfigurator.value_color
            return entity_val, Util::CmsConfigValidator.validate_color(entity_val)
          when GlobalConstant::CmsConfigurator.value_text
            return entity_val, Util::CmsConfigValidator.validate_text(entity_val)
          when GlobalConstant::CmsConfigurator.value_html
            return entity_val, Util::CmsConfigValidator.validate_html(entity_val)
          when GlobalConstant::CmsConfigurator.value_number
            return entity_val, Util::CmsConfigValidator.validate_number(entity_val)
          when GlobalConstant::CmsConfigurator.value_link
            return entity_val, Util::CmsConfigValidator.validate_url(entity_val)
          when GlobalConstant::CmsConfigurator.value_gradient
            return entity_val, 'Invalid Gradient option' if !entity_val.is_a?(Hash)

            color = entity_val[GlobalConstant::CmsConfigurator.value_color]
            err_msg_color = Util::CmsConfigValidator.validate_color(color)
            return entity_val, err_msg_color if err_msg_color.present?

            gradient = entity_val[GlobalConstant::CmsConfigurator.value_gradient]
            err_msg_gradient = Util::CmsConfigValidator.validate_number(gradient)
            return entity_val, err_msg_gradient
          else
            fail "Invalid Data kind - #{data_kind}"
        end
      end


      def basic_validations(entity_value, data_kind, validations)
        modified_entity_value = entity_value

        if data_kind == GlobalConstant::CmsConfigurator.value_array
          max_count = validations[GlobalConstant::CmsConfigurator.max_count_key]
          return modified_entity_value, "Entities cannot be more than #{max_count}" if
              max_count && modified_entity_value.length > max_count

          min_count = validations[GlobalConstant::CmsConfigurator.min_count_key]
          return modified_entity_value, "Entities cannot be less than #{min_count}" if
              min_count && modified_entity_value.length < min_count

        elsif data_kind == GlobalConstant::CmsConfigurator.value_number
          modified_entity_value = entity_value.to_i
          max = validations[GlobalConstant::CmsConfigurator.max_key]
          return modified_entity_value, "Number cannot be more than #{max}" if
              max && modified_entity_value && modified_entity_value > max

          min = validations[GlobalConstant::CmsConfigurator.min_key]
          return modified_entity_value, "Number cannot be less than #{min}" if
              min && modified_entity_value && modified_entity_value < min

        else
          modified_entity_value = entity_value.to_s.strip
          max_length = validations[GlobalConstant::CmsConfigurator.max_length_key]
          return modified_entity_value, "Length cannot be more than #{max_length}" if
              max_length && modified_entity_value.length > max_length

          min_length = validations[GlobalConstant::CmsConfigurator.min_length_key]
          return modified_entity_value, "Length cannot be less than #{min_length}" if
              min_length && modified_entity_value.length < min_length
        end

        includes_validation = validations[GlobalConstant::CmsConfigurator.includes_key]
        return modified_entity_value, "Entered Value is not allowed" if includes_validation && includes_validation.exclude?(modified_entity_value)

        return modified_entity_value, nil
      end

      # Cloudfront domain url
      #
      # * Author: Aniket
      # * Date: 17/08/2018
      # * Reviewed By:
      #
      def cloudfront_domain
        GlobalConstant::Aws::Common.client_assets_cdn_url
      end

      # Validate uploaded files path
      #
      # * Author: Aniket
      # * Date: 17/08/2018
      # * Reviewed By:
      #
      def validate_uploaded_files_path
        err = {}
        GlobalConstant::EntityGroupDraft.theme_entity_type == @entity_type &&
            [GlobalConstant::CmsConfigurator.company_logo_key,
             GlobalConstant::CmsConfigurator.company_favicon_key].each do |key|
              asset_url = @store_data[key.to_sym].to_s.gsub(cloudfront_domain, "")
              if asset_url.present?
                if asset_url.match(AdminManagement::CmsConfigurator::GetUploadParams::CLIENT_ASSET_FILE_PATH_REGEX).blank?
                  err[key.to_sym] = "Filepath is invalid."
                  next
                end
                @store_data[key.to_sym] = cloudfront_domain + asset_url
              end
            end
        return err
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


      def get_response_data
        @params.delete(:form_data)
        AdminManagement::CmsConfigurator::GetEntityDraft.new(@params).perform
      end

    end

  end
end