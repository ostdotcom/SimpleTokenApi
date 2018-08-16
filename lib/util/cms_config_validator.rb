module Util
  class CmsConfigValidator

    COLOR_MATCH_REGEX = /(rgb)\((([01]?[0-9]?[0-9]|2[0-4][0-9]|25[0-5]),\s*){2}([01]?[0-9]?[0-9]|2[0-4][0-9]|25[0-5])\)/i

    class << self

      def validate_cms(text, config)
        data_kind = config[GlobalConstant::CmsConfigurator.data_kind_key]
        validations = config[GlobalConstant::CmsConfigurator.validations_key]

        case data_kind
          when GlobalConstant::CmsConfigurator.value_color
            return  validate_color(text, validations)

          when GlobalConstant::CmsConfigurator.value_number
            return  validate_number(text, validations)

          when GlobalConstant::CmsConfigurator.value_text
            return  validate_text(text, validations)

          when GlobalConstant::CmsConfigurator.value_html
            return validate_html(text, validations)

          when GlobalConstant::CmsConfigurator.value_file
            return  validate_file(text, validations)

          when GlobalConstant::CmsConfigurator.value_array
            return validate_array(text, config)

          else
            puts 'unknown data_kind'
        end

      end

      def validate_color(color_text, validations={})
        color_text.match(COLOR_MATCH_REGEX).present?
      end

      def validate_number(number_text, validations={})
        int_value = Integer(number_text)
        max = validations[GlobalConstant::CmsConfigurator.max_key]

        (max && int_value > max) ? false : true
      rescue
        false
      end

      def validate_text(text, validations={})
        max_length = validations[GlobalConstant::CmsConfigurator.max_length_key]
        return false if max_length && text.length > max_length

        Util::HtmlSanitizer.new({html:text}).perform
      end

      def validate_html(html_text, validations={})
        max_length = validations[GlobalConstant::CmsConfigurator.max_length_key]
        return false if max_length && html_text.length > max_length

        param = {
            elements:['a','br','u','i','b'],
            attributes:{'a':['href','target']},
            html:html_text
        }
        Util::HtmlSanitizer.new(param).perform
      end

      def validate_file(file_text, validations)
        true
      end

      def validate_array(array_obj, config)
        return false if !array_obj.is_a?(Array)

        element = config[GlobalConstant::CmsConfigurator.element_key]
        ele_data_kind = element[GlobalConstant::CmsConfigurator.data_kind_key]
        ele_validations = element[GlobalConstant::CmsConfigurator.validations_key]

        case ele_data_kind
          when GlobalConstant::CmsConfigurator.value_gradient
            return validate_gradient(array_obj, ele_validations)

          when GlobalConstant::CmsConfigurator.value_text
            array_obj.each do |txt_obj|
              r = validate_text(txt_obj, ele_validations)
              return false if !r
            end
          when GlobalConstant::CmsConfigurator.value_html
            array_obj.each do |html_txt|
              r = validate_html(html_txt, ele_validations)
              return false if !r
            end
          else
            puts 'Unkown data_kind for element array.'
        end

      end

      def validate_gradient(gradient_array, validations)
        return false if !gradient_array.is_a?(Array)

        max_length = validations[GlobalConstant::CmsConfigurator.max_length_key]
        return false if max_length && gradient_array.length > max_length

        gradient_array.each do |gradient_obj|
          color = gradient_obj[GlobalConstant::CmsConfigurator.value_color]
          gradient = gradient_obj[GlobalConstant::CmsConfigurator.value_gradient]

          rc =  validate_color(color)
          return false if !rc

          rg = validate_number(gradient)
          return false if !rg

        end

        true
      end

    end

  end
end
