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
        @form_data = @params[:form_data]

        @entity_group, @entity_group_draft, @entity_draft = nil, nil, nil
        @client_settings = nil
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
        have_error = false
        entity_config = fetch_entity_config_for_fe

        entity_config.each do |key, value|
          is_mandatory = value[GlobalConstant::CmsConfigurator.validations_key][GlobalConstant::CmsConfigurator.required_key].to_i
          form_text = @form_data[key.to_sym]
          puts form_text

          if value[GlobalConstant::CmsConfigurator.not_eligible_key].to_i == 1
            @form_data.delete(key.to_sym)

          elsif is_mandatory == 1 && form_text.blank?
            puts "error : Mandatory_blank key: #{key}"
            error_data[key.to_sym] = "This field cannot be blank"
            have_error  = true
          elsif form_text.present?
            validations = value[GlobalConstant::CmsConfigurator.validations_key]

            err_msg = basic_validations(form_text, validations)

            if err_msg.present?
              error_data[key.to_sym] = err_msg
              have_error  = true
              next
            end

            data_kind = value[GlobalConstant::CmsConfigurator.data_kind_key]
            case data_kind
              when GlobalConstant::CmsConfigurator.value_color
                 is_valid = Util::CmsConfigValidator.validate_color(form_text)
                 if !is_valid
                   error_data[key.to_sym] = "Invalid color passed."
                   have_error  = true
                 end
              when GlobalConstant::CmsConfigurator.value_text
                error_text = Util::CmsConfigValidator.validate_text(form_text)
                if error_text.present?
                  error_data[key.to_sym] = error_text
                  have_error  = true
                end

              when GlobalConstant::CmsConfigurator.value_html
                error_text = Util::CmsConfigValidator.validate_html(form_text)
                if error_text.present?
                  error_data[key.to_sym] = error_text
                  have_error  = true
                end


              when GlobalConstant::CmsConfigurator.value_number
                is_valid = Util::CmsConfigValidator.validate_number(form_text)
                if !is_valid
                  error_data[key.to_sym] = "Invalid number passed."
                  have_error  = true
                end

              when GlobalConstant::CmsConfigurator.value_link
                is_valid = Util::CmsConfigValidator.validate_url(form_text)
                if !is_valid
                  error_data[key.to_sym] = "Invalid URL passed."
                  have_error  = true
                end

              when GlobalConstant::CmsConfigurator.value_array
                element = value[GlobalConstant::CmsConfigurator.element_key]
                ele_data_kind = element[GlobalConstant::CmsConfigurator.data_kind_key]
                ele_validations = element[GlobalConstant::CmsConfigurator.validations_key]

                form_text.each_with_index do |obj, index|
                  error_data[key.to_sym] = [] if error_data[key.to_sym].blank?

                  err_msg = basic_validations(obj,ele_validations)
                  if err_msg.present?
                    error_data[key.to_sym][index] = err_msg
                    have_error  = true
                    next
                  end

                  case ele_data_kind
                    when GlobalConstant::CmsConfigurator.value_text
                      error_text = Util::CmsConfigValidator.validate_text(obj)
                      if error_text.present?
                        error_data[key.to_sym][index] = error_text
                        have_error  = true
                      end

                    when GlobalConstant::CmsConfigurator.value_html
                      error_text = Util::CmsConfigValidator.validate_html(obj)
                      if error_text.present?
                        error_data[key.to_sym][index] = error_text
                        have_error  = true
                      end

                    when GlobalConstant::CmsConfigurator.value_gradient
                      error_data[key.to_sym][index] = {} if error_data[key.to_sym][index].blank?

                      gradient = obj[GlobalConstant::CmsConfigurator.value_gradient]
                      is_valid = Util::CmsConfigValidator.validate_number(gradient)
                      if !is_valid
                        error_data[key.to_sym][index][GlobalConstant::CmsConfigurator.value_gradient] = "Invalid number passed."
                        have_error  = true
                      end
                      color = obj[GlobalConstant::CmsConfigurator.value_color]
                      is_valid = Util::CmsConfigValidator.validate_color(color)
                      if !is_valid
                        error_data[key.to_sym][index][GlobalConstant::CmsConfigurator.value_color] = "Invalid color passed."
                        have_error  = true
                      end
                  end
                end

            end
          end
        end

        case @entity_type
          when GlobalConstant::EntityGroupDraft.theme_entity_type
            theme_error_data = theme_related_validations
            if theme_error_data.present?
              error_data = theme_error_data.merge(error_data)
              have_error  = true
            end
        end

        return error_with_data(
            's_cc_up_favfd_1',
            'Validation failed',
            "Validation failed",
            GlobalConstant::ErrorAction.default,
            error_data
        ) if have_error

        success
      end

      def basic_validations(text, validations)
        max_length = validations[GlobalConstant::CmsConfigurator.max_length_key]
        return "Length cannot be more than #{max_length}" if max_length && text.length > max_length

        min_length = validations[GlobalConstant::CmsConfigurator.min_length_key]
        return "Length cannot be less than #{min_length}" if min_length && text.length < min_length

        includes_validation = validations[GlobalConstant::CmsConfigurator.includes_key]
        return "Entered Value is not allowed" if includes_validation && includes_validation.include?(text)

        ""
      end

      # Validate theme related config.
      #
      # * Author: Aniket
      # * Date: 20/08/2018
      # * Reviewed By:
      #
      def theme_related_validations
        theme_error_data = {}

        company_logo = @form_data[GlobalConstant::CmsConfigurator.company_logo_key]
        theme_error_data[GlobalConstant::CmsConfigurator.company_logo_key.to_sym] = "Wrong company logo URL." if
            company_logo.match(/(c_assets)/i).blank?

        company_favicon = @form_data[GlobalConstant::CmsConfigurator.company_favicon_key]
        if company_favicon.present?
          theme_error_data[GlobalConstant::CmsConfigurator.company_favicon_key.to_sym] = "Wrong company favicon URL." if
          company_favicon.match(/(c_assets)/i).blank?
        end

        puts theme_error_data
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