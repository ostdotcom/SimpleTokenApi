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

        err_data = {}
        err_data[:is_published] = 1 if @entity_group.status == GlobalConstant::EntityGroup.active_status
        return error_with_data(
            's_cc_ued_fave_3',
            'invalid entity params',
            "This version has already been published and cannot be updated. To make changes to a published
                        version, please create a new draft.",
            GlobalConstant::ErrorAction.default,
            {},
            err_data
        ) if @entity_group.status != GlobalConstant::EntityGroup.incomplete_status

        success
      end

      # Fetch and validate page yml
      #
      # * Author: Aniket
      # * Date: 28/08/2018
      # * Reviewed By:
      #
      def fetch_and_validate_form_data
        error_data = {}
        entity_config = fetch_entity_config_for_fe

        entity_config.each do |key, entity_config|
          next if entity_config[GlobalConstant::CmsConfigurator.not_eligible_key].to_i == 1
          entity_val = Oj.load(@form_data[key.to_sym].to_json, {})
          r = validate_and_sanitize_field_recursively(entity_val, entity_config)
          if r.success?
            sanitized_val = r.data[:sanitized_val]
            @store_data[key.to_sym] = sanitized_val if sanitized_val.present?
          else
            error_data.merge!({"#{key}": r.error_data[:err]})
          end
        end

        error_data.reverse_merge!(validate_uploaded_files_path)
        error_data.reverse_merge!(validate_pixels)
        error_data.reverse_merge!(validate_fb_version)


        return error_with_data(
            's_cc_up_favfd_1',
            'Validation failed',
            "Validation failed",
            GlobalConstant::ErrorAction.default,
            {},
            Util::CustomErrorFormatter.format_error_for_update_config(error_data)
        ) if error_data.present?

        success
      end

      # validate and sanitize fields recursively
      #
      # * Author: Aniket
      # * Date: 28/08/2018
      # * Reviewed By:
      #
      def validate_and_sanitize_field_recursively(entity_val, entity_config)
        result_obj = nil

        # max_length, min_length, required, includes
        entity_validations = entity_config[GlobalConstant::CmsConfigurator.validations_key]
        is_mandatory = entity_validations[GlobalConstant::CmsConfigurator.required_key].to_i if entity_validations.present?
        return error_result_obj("This field cannot be blank") if is_mandatory == 1 && entity_val.blank?
        return success_with_data(sanatize_val: nil) if entity_val.nil?

        if entity_val.is_a? String
          # if the entity_val is a string, sanitize it directly to remove script tags etc
          result_obj = validate_and_sanitize_field(entity_val, entity_config)

        elsif entity_val.is_a?(Hash) || entity_val.is_a?(ActionController::Parameters)
          err_data, sanitized_data = {}, {}
          entity_val.each do |key, val|
            r = validate_and_sanitize_field_recursively(val, entity_config[key])

            unless r.success?
              err_data[key.to_sym] = r.error_data[:err]
            else
              sanitized_data[key.to_sym] = r.data[:sanitized_val]
            end

          end
          result_obj = err_data.present? ? error_result_obj(err_data) :
                           success_with_data(sanitized_val: sanitized_data)

        elsif entity_val.is_a?(Array)
          err_data, sanitized_data = {}, []

          r = Util::CmsConfigValidator.basic_validate_array(entity_val, entity_config[GlobalConstant::CmsConfigurator.validations_key])
          return r if !r.success?

          entity_val.each_with_index do |val, index|
            r = validate_and_sanitize_field_recursively(val, entity_config[GlobalConstant::CmsConfigurator.element_key])

            if r.success?
              sanitized_data << r.data[:sanitized_val]
            else
              err_data[index] = r.error_data[:err]
              # insert a nil value so that the sequence of values is maintained
              sanitized_data << nil
            end
          end

          result_obj = err_data.present? ? error_result_obj(err_data) :
                           success_with_data(sanitized_val: sanitized_data)
        end
        return result_obj
      rescue => e
        return exception_with_data(
            e,
            'am_cc_ued_vasfr_1',
            'Invalid Data type ' + e.message,
            '',
            GlobalConstant::ErrorAction.default,
            {err: 'Invalid Data type'}
        )
      end

      # Validate fields on the basis of data_type
      #
      # * Author: Aniket
      # * Date: 28/08/2018
      # * Reviewed By:
      #
      def validate_and_sanitize_field(entity_val, entity_config)
        data_kind = entity_config[GlobalConstant::CmsConfigurator.data_kind_key]
        validations = entity_config[GlobalConstant::CmsConfigurator.validations_key]
        response_data = nil

        case data_kind
          when GlobalConstant::CmsConfigurator.value_text
            response_data = Util::CmsConfigValidator.validate_text(entity_val, validations)

          when GlobalConstant::CmsConfigurator.value_html
            response_data = Util::CmsConfigValidator.validate_html(entity_val, validations)

          when GlobalConstant::CmsConfigurator.value_color
            response_data = Util::CmsConfigValidator.validate_color(entity_val, validations)

          when GlobalConstant::CmsConfigurator.value_number
            response_data = Util::CmsConfigValidator.validate_number(entity_val, validations)

          when GlobalConstant::CmsConfigurator.value_link
            response_data = Util::CmsConfigValidator.validate_url(entity_val, validations)
        end
        response_data
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
              asset_url = @store_data[key.to_sym].to_s.gsub(cloudfront_domain_prefix, "")
              if asset_url.present?
                if asset_url.match(AdminManagement::CmsConfigurator::GetUploadParams::CLIENT_ASSET_FILE_PATH_REGEX).blank?
                  err[key.to_sym] = "Filepath is invalid."
                  next
                end
                @store_data[key.to_sym] = cloudfront_domain_prefix + asset_url
              end
            end
        err
      end

      # Validate pixel values
      #
      # * Author: Aniket
      # * Date: 21/09/2018
      # * Reviewed By:
      #
      def validate_pixels
        err = {}
        GlobalConstant::EntityGroupDraft.theme_entity_type == @entity_type &&
            [GlobalConstant::CmsConfigurator.gtm_pixel_id_key,
             GlobalConstant::CmsConfigurator.fb_pixel_id_key].each do |key|
              pixel_value = @store_data[key.to_sym]
              if pixel_value.present?
                err[key.to_sym] = "Invalid value for #{key}" unless pixel_value.match(/\A[a-z0-9]*\z/i)
              end
            end
        err
      end

      # Validate fb version values
      #
      # * Author: Aniket
      # * Date: 21/09/2018
      # * Reviewed By:
      #
      def validate_fb_version
        err = {}
        return {} unless GlobalConstant::EntityGroupDraft.theme_entity_type == @entity_type

        key = GlobalConstant::CmsConfigurator.fb_pixel_version_key
        fb_version_value = @store_data[key.to_sym]
        if fb_version_value.present?
          err[key.to_sym] = "Invalid value for #{key}" unless fb_version_value.match(/\Av[0-9\.]*\z/i)
        elsif @store_data[GlobalConstant::CmsConfigurator.fb_pixel_id_key.to_sym].present?
          err[key.to_sym] = "Please provide the #{key}"
        end

        err
      end

      # Cloudfront domain url
      # domain ends with '/'
      #
      # * Author: Aniket
      # * Date: 17/08/2018
      # * Reviewed By:
      #
      def cloudfront_domain_prefix
        "#{GlobalConstant::Aws::Common.client_assets_cdn_url}/"
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

      # Get response data for frontend
      #
      # * Author: Aniket
      # * Date: 17/08/2018
      # * Reviewed By:
      #
      def get_response_data
        @params.delete(:form_data)
        AdminManagement::CmsConfigurator::GetEntityDraft.new(@params).perform
      end

      # returns error object
      # AdminManagement::CmsConfigurator.fetch_and_validate_form_data expect error in error_data for key :err
      #
      # * Author: Aniket
      # * Date: 28/08/2018
      # * Reviewed By:
      #
      def error_result_obj(error)
        error_with_data(
            'am_cc_ued_ero_1',
            'Invalid fields value',
            '',
            GlobalConstant::ErrorAction.default,
            {},
            {err: error}
        )
      end

    end

  end
end