module Util
  class CmsConfigValidator

    COLOR_MATCH_REGEX = /(rgb)\((([01]?[0-9]?[0-9]|2[0-4][0-9]|25[0-5]),\s*){2}([01]?[0-9]?[0-9]|2[0-4][0-9]|25[0-5])\)/i

    class << self

      def cms_validate(text, config)
        data_kind = config[GlobalConstant::CmsConfigurator.data_kind_key]

        case data_kind
          when GlobalConstant::CmsConfigurator.value_color
            return  validate_color(text)
          when GlobalConstant::CmsConfigurator.value_number
            return  validate_number(text)
          when GlobalConstant::CmsConfigurator.value_text
            return  validate_text(text)
          when GlobalConstant::CmsConfigurator.value_file
            return  validate_file(text)
          when GlobalConstant::CmsConfigurator.value_array
            return validate_array(text)
          when GlobalConstant::CmsConfigurator.value_html
            return validate_html(text)
          else
            puts 'unknown data_kind'
        end

      end

      def validate_color(text)
        text.match(COLOR_MATCH_REGEX).present?
      end

      def validate_text(text)
        Util::HtmlSanitizer.new({html:text}).perform
      end

      def validate_html(text)
        param = {
            elements:['a','br','u','i','b'],
            attributes:{'a':['href','target']},
            html:text
        }
        Util::HtmlSanitizer.new(param).perform
      end

      def validate_number(text)
        true if Integer(text) rescue false
      end

      def validate_array(text)
        text.is_a?(Array)
      end

      def validate_file(text)
        true
      end

    end

  end
end
