# frozen_string_literal: true
module GlobalConstant
  class CmsConfigurator

    class << self


      ######### YML keys and values #############

      def company_favicon_key
        'company_favicon'
      end

      def company_logo_key
        'company_logo'
      end

      def gtm_pixel_id_key
        'gtm_pixel_id'
      end

      def fb_pixel_id_key
        'fb_pixel_id'
      end

      def fb_pixel_version_key
        'fb_pixel_version'
      end

      def not_eligible_key
        'not_eligible'
      end

      def data_kind_key
        'data_kind'
      end

      def required_key
        'required'
      end

      def validations_key
        'validations'
      end

      def element_key
        'element'
      end

      def min_key
        'min'
      end

      def min_bytes_key
        "min_bytes"
      end

      def max_bytes_key
        "max_bytes"
      end

      def max_length_key
        'max_length'
      end

      def min_length_key
        'min_length'
      end

      def max_count_key
        'max_count'
      end

      def min_count_key
        'min_count'
      end

      def includes_key
        'includes'
      end

      def accept_key
        'accept'
      end

      def max_key
        'max'
      end

      def value_color
        'color'
      end

      def value_text
        'text'
      end

      def value_number
        'number'
      end

      def value_array
        'array'
      end

      def value_html
        'html'
      end

      def value_link
        'link'
      end

      def value_gradient
        'gradient'
      end

      ######### YML keys and values end#############

      def get_entity_config(entity_type)
        config = case entity_type
                   when GlobalConstant::EntityGroupDraft.theme_entity_type
                     get_theme_yml
                   when GlobalConstant::EntityGroupDraft.kyc_entity_type
                     get_kyc_yml
                   when GlobalConstant::EntityGroupDraft.dashboard_entity_type
                     get_dashboard_yml
                   when GlobalConstant::EntityGroupDraft.registration_entity_type
                     get_registration_yml
                   else
                     raise "invalid entity type-#{entity_type}"
                 end
        config.deep_dup
      end

      #
      def get_client_blocked_fields(entity_type, client_settings)
        blocked_fields = []
        token_sale_details = client_settings[:token_sale_details]
        kyc_fields = client_settings[:kyc_config_detail_data][:kyc_fields]
        case entity_type
          when GlobalConstant::EntityGroupDraft.dashboard_entity_type
            if !token_sale_details[:has_ethereum_deposit_address]
              blocked_fields += ["ethereum_deposit_popup_checkboxes"]
            end

          when GlobalConstant::EntityGroupDraft.kyc_entity_type
            if kyc_fields.exclude?("ethereum_address")
              blocked_fields << "eth_address_instruction_text"
            end
        end
        blocked_fields
      end

      # Entity config for BE for extra kyc fields instruction_text
      #
      # * Author: Mayur
      # * Date: 05/11/2018
      # * Reviewed By:
      #
      # @return [Hash]
      #
      def extra_kyc_field_instruction_text_config
        @extra_kyc_field_instruction_text_config ||= {
            data_kind: 'html',
            validations: {
                required: 0
            },
            max_length: 400,
            default_value: ''

        }.deep_stringify_keys
      end

      # Entity config for FE for extra kyc fields instruction_text
      #
      # * Author: Mayur
      # * Date: 05/11/2018
      # * Reviewed By:
      #
      # @return [Hash] frontend config needed for configurator form build
      #
      def get_fe_config_for_instruction_text(key)
        {
            label:  "#{key} #{extra_kyc_field_instruction_text_suffix}",
            placeholder: "",
            tooltip: "",
            inputType: "rich_text_editor"
        }.deep_stringify_keys
      end


      # extra kyc fields instruction_text display section config for FE
      #
      # * Author: Mayur
      # * Date: 05/11/2018
      # * Reviewed By:
      #
      # @return [Hash] collapse config needed for configurator form build
      #
      def get_dynamic_fields_fe_sequence_config(extra_kyc_fields_instructon_keys)
        {
                kyc_form: {
                    kyc_configuration: {
                        entities: ["kyc_form_title", "kyc_form_subtitle", "eth_address_instruction_text",
                                   "document_id_instruction_text"] + extra_kyc_fields_instructon_keys
                    }

                }
        }.deep_stringify_keys

      end

      # suffix for extra kyc fields instruction text field in configurator
      #
      # * Author: Mayur
      # * Date: 05/11/2018
      # * Reviewed By:
      #
      # @return [Hash] this is the suffix for all extra kyc fields instruction text key used in configurator
      #
      def extra_kyc_field_instruction_key_suffix
        "_dynamic_kyc_field_instruction_text"
      end

      def extra_kyc_field_instruction_text_suffix
        "instruction text"
      end

      def get_entity_config_for_fe(entity_type, client_settings)
        config = get_entity_config(entity_type)
        blocked_fields = get_client_blocked_fields(entity_type, client_settings)

        if entity_type == GlobalConstant::EntityGroupDraft.kyc_entity_type
          extra_kyc_fields = client_settings[:kyc_config_detail_data][:extra_kyc_fields]
          extra_kyc_fields.each do |kyc_field, _|
            config["#{kyc_field.to_s}#{extra_kyc_field_instruction_key_suffix}"] = extra_kyc_field_instruction_text_config
          end
        end

        config.present? && config.each do |key, value|
          new_val = (value[GlobalConstant::CmsConfigurator.data_kind_key] == 'array') ? "#{key}[]" : key
          config[key].merge!('data_key_name' => new_val)
          config[key].delete("default_value")
          config[key].merge!(not_eligible_key => 1) if blocked_fields.include?(key)
        end
        config
      end

      def custom_default_template_data
        @custom_default_template_data ||= begin
          default_template_data = {}
          default_template_data[GlobalConstant::EntityGroupDraft.theme_entity_type] = {}
          default_template_data[GlobalConstant::EntityGroupDraft.registration_entity_type] = {}
          default_template_data[GlobalConstant::EntityGroupDraft.kyc_entity_type] = {}
          default_template_data[GlobalConstant::EntityGroupDraft.dashboard_entity_type] = {}

          get_theme_yml.each do |key, data|
            default_val = data["default_value"]
            next if default_val.blank?

            if [company_logo_key, company_favicon_key].include?(key)
              default_val = "#{GlobalConstant::Aws::Common.client_assets_cdn_url}/" + default_val
            end

            default_template_data[GlobalConstant::EntityGroupDraft.theme_entity_type][key.to_sym] = default_val
          end

          get_registration_yml.each do |key, data|
            default_val = data["default_value"]
            next if default_val.blank?
            default_template_data[GlobalConstant::EntityGroupDraft.registration_entity_type][key.to_sym] = default_val
          end

          get_kyc_yml.each do |key, data|
            default_val = data["default_value"]
            next if default_val.blank?
            default_template_data[GlobalConstant::EntityGroupDraft.kyc_entity_type][key.to_sym] = default_val
          end

          get_dashboard_yml.each do |key, data|
            default_val = data["default_value"]
            next if default_val.blank?
            default_template_data[GlobalConstant::EntityGroupDraft.dashboard_entity_type][key.to_sym] = default_val
          end
          default_template_data
        end
        @custom_default_template_data.deep_dup
      end

      #min bytes 1kb and max bytes 2MB
      def company_logo_file_size_range
        @company_logo_range ||= begin
          validations = get_theme_yml[company_logo_key][validations_key]
          validations[min_bytes_key]..validations[max_bytes_key]
        end
      end

      #min bytes 1kb and max bytes 200kb
      def company_favicon_file_size_range
        @company_favicon_range ||= begin
          validations = get_theme_yml[company_favicon_key][validations_key]
          validations[min_bytes_key]..validations[max_bytes_key]
        end
      end

      def company_logo_file_formats
        @company_logo_ff ||= begin
          validations = get_theme_yml[company_logo_key][validations_key]
          validations[accept_key]
        end
      end

      def company_favicon_file_formats
        @company_fav_ff ||= begin
          validations = get_theme_yml[company_favicon_key][validations_key]
          validations[accept_key]
        end
      end

      def get_dashboard_yml
        @dashboard_yml ||= YAML.load_file(open(Rails.root.to_s + '/config/fe_configurator/dashboard.yml'))
      end

      def get_kyc_yml
        @kyc_yml ||= YAML.load_file(open(Rails.root.to_s + '/config/fe_configurator/kyc.yml'))
      end

      def get_registration_yml
        @registration_yml ||= YAML.load_file(open(Rails.root.to_s + '/config/fe_configurator/registration.yml'))
      end

      def get_theme_yml
        @theme_yml ||= YAML.load_file(open(Rails.root.to_s + '/config/fe_configurator/theme.yml'))
      end

    end

  end
end
