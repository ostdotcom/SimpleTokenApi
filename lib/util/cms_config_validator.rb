module Util
  class CmsConfigValidator

    COLOR_MATCH_REGEX = /^(rgb)\((([01]?[0-9]?[0-9]|2[0-4][0-9]|25[0-5]),\s*){2}([01]?[0-9]?[0-9]|2[0-4][0-9]|25[0-5])\)$/i

    class << self

      include ::Util::ResultHelper

      # Validate color
      #
      # * Author: Aniket
      # * Date: 28/04/2018
      # * Reviewed By:
      #
      def validate_color(color_text, validations)
        r = basic_validate_and_sanitize_string(color_text, validations)
        return r if !r.success?
        color_text = r.data[:sanitized_val]

        color_text.to_s.match(COLOR_MATCH_REGEX).present? ?
            success_with_data(sanitized_val: color_text) : error_result_obj("Invalid color passed.")
      end

      # Validate number
      #
      # * Author: Aniket
      # * Date: 28/04/2018
      # * Reviewed By:
      #
      def validate_number(number_text, validations)
        r = basic_validate_number(number_text, validations)
        return r if !r.success?
        number_text = r.data[:sanitized_val]

        success_with_data(sanitized_val: number_text.to_i) if Integer(number_text)
      rescue error_result_obj("Invalid number passed.")
      end

      # Validate text
      #
      # * Author: Aniket
      # * Date: 28/04/2018
      # * Reviewed By:
      #
      def validate_text(text, validations)
        r = basic_validate_and_sanitize_string(text, validations)
        return r if !r.success?
        text = r.data[:sanitized_val]

        success_with_data(sanitized_val: Sanitize.fragment(text))
      end

      # Validate html
      #
      # * Author: Aniket
      # * Date: 28/04/2018
      # * Reviewed By:
      #
      def validate_html(html_text, validations)
        # unescapeHTML is doing here, because we are doing escapeHTML in before_filter for update_entity_draft method
        html_text = CGI.unescapeHTML(html_text)
        html_text.to_s.strip

        #removing max length validations for html fields.
        # r = basic_validate_and_sanitize_string(html_text, validations)
        # return r if !r.success?
        # html_text = r.data[:sanitized_val]
        #

        success_with_data(sanitized_val: Sanitize.fragment(html_text, custom_sanitizer_config))
      end

      # Get allowed html fields for sanitizer
      #
      # * Author: Aniket
      # * Date: 28/04/2018
      # * Reviewed By:
      #
      def custom_sanitizer_config
        {
            :elements => ['a', 'br', 'span', 'em', 'strong'],

            :attributes => {
                'a' => ['href', 'target', 'rel', 'title'],
                'span' => ['style']
            },
            :protocols =>{
                'a'   => {'href' => ['http', 'https']}
            },
            :add_attributes => {
                'a' => {'rel' => 'nofollow'}
            },
            :css => {
                :properties => ['text-decoration']
            }
        }
      end

      # Validate url
      #
      # * Author: Aniket
      # * Date: 28/04/2018
      # * Reviewed By:
      #
      def validate_url(link_text, validations)
        r = basic_validate_and_sanitize_string(link_text, validations)
        return r if !r.success?
        link_text = r.data[:sanitized_val]

        uri_value = URI.parse(link_text)

        if allowed_uri_class.include?(uri_value.class)
          success_with_data(sanitized_val: link_text)
        else
          error_result_obj("only https/http links are allowed")
        end
      rescue => e
        error_result_obj("Invalid URL passed.")
      end

      # Get allowed URI class
      #
      # * Author: Aniket
      # * Date: 21/09/2018
      # * Reviewed By:
      #
      def allowed_uri_class
        [URI::HTTP, URI::HTTPS]
      end

      # Basic Validations starts

      # Check basic validations for array
      #
      # * Author: Aniket
      # * Date: 28/04/2018
      # * Reviewed By:
      #
      def basic_validate_array(entity_val, validations)
        max_count = validations[GlobalConstant::CmsConfigurator.max_count_key]
        return error_result_obj("Entities cannot be more than #{max_count}") if max_count && entity_val.length > max_count

        min_count = validations[GlobalConstant::CmsConfigurator.min_count_key]
        return error_result_obj("Entities cannot be less than #{min_count}") if min_count && entity_val.length < min_count

        basic_validate_includes(entity_val, validations)
      end

      # Check basic validations for number
      #
      # * Author: Aniket
      # * Date: 28/04/2018
      # * Reviewed By:
      #
      def basic_validate_number(entity_val, validations)
        max = validations[GlobalConstant::CmsConfigurator.max_key]
        return error_result_obj("Number cannot be more than #{max}") if max && entity_val && entity_val.to_i > max

        min = validations[GlobalConstant::CmsConfigurator.min_key]
        return error_result_obj("Number cannot be less than #{min}") if min && entity_val && entity_val.to_i < min

        basic_validate_includes(entity_val, validations)
      end

      # Check basic validations for string
      #
      # * Author: Aniket
      # * Date: 28/04/2018
      # * Reviewed By:
      #
      def basic_validate_and_sanitize_string(entity_val, validations)
        entity_val = entity_val.to_s.strip

        max_length = validations[GlobalConstant::CmsConfigurator.max_length_key]
        return error_result_obj("Length cannot be more than #{max_length}") if max_length && entity_val.length > max_length

        min_length = validations[GlobalConstant::CmsConfigurator.min_length_key]
        return error_result_obj("Length cannot be less than #{min_length}") if min_length && entity_val.length < min_length

        basic_validate_includes(entity_val, validations)
      end

      # Check basic validations for allowed values
      #
      # * Author: Aniket
      # * Date: 28/04/2018
      # * Reviewed By:
      #
      def basic_validate_includes(entity_val, validations)
        includes_validation = validations[GlobalConstant::CmsConfigurator.includes_key]
        return error_result_obj("Entered Value is not allowed") if includes_validation && includes_validation.exclude?(entity_val)

        success_with_data(sanitized_val: entity_val)
      end

      # returns error object
      # AdminManagement::CmsConfigurator.fetch_and_validate_form_data expect error in error_data for key :err
      #
      # * Author: Aniket
      # * Date: 28/08/2018
      # * Reviewed By:
      #
      def error_result_obj(error_text)
        error_with_data(
            'ccv_1',
            'Invalid fields value',
            '',
            GlobalConstant::ErrorAction.default,
            {},
            {err: error_text}
        )
      end

    end

  end
end
