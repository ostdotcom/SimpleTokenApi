module Util
  class HtmlSanitizer

    # Initialize
    #
    # @params (Array) elements (optional) - Html tags
    # @params (Hash) attributes (optional) - Html tag attributes
    # @params (String) html () - Html string
    #
    # * Author: Aniket
    # * Date: 08/09/2018
    # * Reviewed By:
    #
    # Set @elements, @attributes, @html
    #
    # @return [Util::HtmlSanitizer]
    #
    def initialize(params)
      @elements = params[:elements] ||= []
      @attributes = params[:attributes] ||= {} #{'a': ['href', 'target']}
      @html = params[:html]
    end

    def perform
      nokogiri_html = Nokogiri::HTML.fragment(@html) do |config|
        config.options = Nokogiri::XML::ParseOptions::STRICT
      end

      if nokogiri_html.errors.length > 0
        noko_error = nokogiri_html.errors.first
        return noko_error.message.gsub("#{noko_error.line}:#{noko_error.column}: ERROR: ","")
      else
        return trigger_function(nokogiri_html)
      end
    rescue
      "Error occurred while converting html."
    end


    def trigger_function(obj)

      if obj.class == Nokogiri::HTML::Document
        return trigger_function(obj.children)

      elsif obj.class == Nokogiri::HTML::DocumentFragment
          return trigger_function(obj.children)

      elsif obj.class == Nokogiri::XML::DTD
        return ""

      elsif obj.class == Nokogiri::XML::Element
        return valid_element?(obj)

      elsif obj.class == Nokogiri::XML::Text
        return ""

      elsif obj.class == Nokogiri::XML::Attr
        invalid_attributes = valid_attributes?(obj.name, obj.attributes)
        if invalid_attributes.length > 0
          attribute_text  = invalid_attributes.length ==1 ? "attribute" : "attributes"
          return "#{obj.name} tag having extra #{attribute_text}: #{invalid_attributes}"
        end
        return ""

      elsif obj.class == Nokogiri::XML::NodeSet
        return valid_nodeset?(obj)
      end

      ""
    end

    def valid_nodeset?(node_set)
      node_set.each_with_index do |obj, index|
        error_text = trigger_function(obj)
        if error_text.present?
          return error_text
        end
      end
      ""
    end

    def valid_element?(element)
      if @elements.include?(element.name)
        invalid_attributes = valid_attributes?(element.name, element.attributes)
        if invalid_attributes.length > 0
          attribute_text  = invalid_attributes.length ==1 ? "attribute" : "attributes"
          return "Tag #{element.name} having extra #{attribute_text}: #{invalid_attributes}"
        end
        return trigger_function(element.children)
      end

      "#{element.name} tag not allowed."
    end

    def valid_attributes?(ele_name, ele_attributes)
      allowed_attributes = @attributes[ele_name.to_sym] || []
      (ele_attributes.keys - allowed_attributes)
    end

  end
end
