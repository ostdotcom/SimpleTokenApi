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

      def max_key
        'max'
      end

      def min_key
        'min'
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
        case entity_type
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

      def get_entity_config_for_fe(entity_type, client_settings)
        config = get_entity_config(entity_type)
        blocked_fields = get_client_blocked_fields(entity_type, client_settings)

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
            default_template_data[GlobalConstant::EntityGroupDraft.theme_entity_type][key] = data[:default_value]
          end

          get_registration_yml.each do |key, data|
            default_template_data[GlobalConstant::EntityGroupDraft.registration_entity_type][key] = data[:default_value]
          end

          get_kyc_yml.each do |key, data|
            default_template_data[GlobalConstant::EntityGroupDraft.kyc_entity_type][key] = data[:default_value]
          end

          get_dashboard_yml.each do |key, data|
            default_template_data[GlobalConstant::EntityGroupDraft.dashboard_entity_type][key] = data[:default_value]
          end
          default_template_data
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
