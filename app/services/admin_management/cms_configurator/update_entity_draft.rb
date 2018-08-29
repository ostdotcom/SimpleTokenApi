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

        return error_with_data(
            's_cc_up_favfd_1',
            'Validation failed',
            "Validation failed",
            GlobalConstant::ErrorAction.default,
            {},
            format_error_for_update_config(error_data)
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
        return success_with_data(sanatize_val:nil) if entity_val.nil?

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

      # Format deep error hash in single level hash
      #
      # * Author: Aniket
      # * Date: 28/08/2018
      # * Reviewed By:
      #
      def format_error_for_update_config(error_data)
        formatted_errors = {}
        error_data.each do |key, val|
          formatted_errors.merge!(get_error(val, key))
        end
        formatted_errors
      end

      # Format deep error hash in single level hash recursively
      #
      # * Author: Aniket
      # * Date: 28/08/2018
      # * Reviewed By:
      #
      def get_error(error, prefix)
        err = {}
        if error.is_a? String
          # if the passed_param is a string, sanitize it directly to remove script tags etc
          err["#{prefix}"] = error
        elsif error.is_a?(Hash)
          # if the passed_param is a hash, sanitize the values.
          # we are not sanitizing keys, as not known keys will not be accessed - assumption
          error.each do |err_key, err_val|
            err.merge!(get_error(err_val, "#{prefix}[#{err_key}]"))
          end
        elsif error.is_a? Array
          # if passed_param is a array, sanitize each element
          error.each_with_index do |err_val, index|
            err.merge!(get_error(err_val, "#{prefix}[#{index}]"))
          end
        end
        err
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

        err
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
            {err:error}
        )
      end

    end

  end
end