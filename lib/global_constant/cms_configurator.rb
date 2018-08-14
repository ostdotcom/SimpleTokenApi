# frozen_string_literal: true
module GlobalConstant
  class CmsConfigurator

    class << self


      ######### YML keys and values #############

      def data_kind_key
        'data_kind'
      end

      def required_key
        'required'
      end

      def validations_key
        'validations'
      end

      def value_color
        'color'
      end

      def value_text
        'text'
      end

      def value_file
        'file'
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

      ######### YML keys and values end#############

      def get_entity_config(entity_type)
        case entity_type
        when GlobalConstant::EntityDraft.theme_entity_type
          get_theme_yml
        when GlobalConstant::EntityDraft.kyc_form_entity_type
          get_kyc_form_yml
        when GlobalConstant::EntityDraft.dashboard_entity_type
          get_dashboard_yml
        when GlobalConstant::EntityDraft.registration_entity_type
          get_registration_yml
        else
          Fail "invalid entity type-#{entity_type}"
        end
      end

      def custom_default_template_data
        @custom_default_template_data ||= begin
          default_template_data = {}
          default_template_data[GlobalConstant::EntityGroupDraft.theme_entity_type] = {}
          default_template_data[GlobalConstant::EntityGroupDraft.registration_entity_type] = {}
          default_template_data[GlobalConstant::EntityGroupDraft.kyc_form_entity_type] = {}
          default_template_data[GlobalConstant::EntityGroupDraft.dashboard_entity_type] = {}

          get_theme_yml.each do |key, data|
            default_template_data[GlobalConstant::EntityGroupDraft.theme_entity_type][key] = data[:default_value]
          end

          get_registration_yml.each do |key, data|
            default_template_data[GlobalConstant::EntityGroupDraft.registration_entity_type][key] = data[:default_value]
          end

          get_kyc_form_yml.each do |key, data|
            default_template_data[GlobalConstant::EntityGroupDraft.kyc_form_entity_type][key] = data[:default_value]
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

      def get_kyc_form_yml
        @kyc_form_yml ||= YAML.load_file(open(Rails.root.to_s + '/config/fe_configurator/kyc_form.yml'))

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
