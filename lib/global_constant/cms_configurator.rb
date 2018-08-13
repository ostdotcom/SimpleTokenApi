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
        puts "entity_typesssssssss : #{entity_type}"
        if entity_type == GlobalConstant::EntityDraft.theme_entity_type
         return get_theme_yml
        elsif entity_type == GlobalConstant::EntityDraft.kyc_form_entity_type
          return get_kyc_form_yml
        elsif entity_type == GlobalConstant::EntityDraft.dashboard_entity_type
          return get_dashboard_yml
        elsif entity_type == GlobalConstant::EntityDraft.registration_entity_type
          return get_registration_yml
        else
          return {}
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
