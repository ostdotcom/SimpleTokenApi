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
