module Util
  class CmsConfigValidator

    COLOR_MATCH_REGEX = /(rgb)\((([01]?[0-9]?[0-9]|2[0-4][0-9]|25[0-5]),\s*){2}([01]?[0-9]?[0-9]|2[0-4][0-9]|25[0-5])\)/i

    class << self

      def validate_color(color_text)
        color_text.to_s.match(COLOR_MATCH_REGEX).present? ? nil : "Invalid color passed."
      end

      def validate_number(number_text)
        nil if Integer(number_text) rescue "Invalid number passed."
      end

      def validate_text(text)
        Util::HtmlSanitizer.new({html:text}).perform
      end

      def validate_html(html_text)
        param = {
            elements:['a','br','u','i','b'],
            attributes:{'a':['href','target', 'rel', 'title']},
            html: html_text
        }
        Util::HtmlSanitizer.new(param).perform
      end

      def validate_url(link_text)
        nil if URI.parse(link_text) rescue "Invalid URL passed."
      end

    end

  end
end
