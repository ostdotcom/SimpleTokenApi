module Util
  class NokogiriHtmlValidator

    # Initialize
    #
    # @params (Array) elements (optional) - Html tags
    # @params (Hash) attributes (optional) - Html tag attributes
    # @params (Hash) attribute_value (optional) - Allowed values for tag attributes
    # @params (String) html () - Html string
    #
    # * Author: Aniket
    # * Date: 08/09/2018
    # * Reviewed By:
    #
    # Set @elements, @attributes, @html
    #
    # @return [Util::NokogiriHtmlValidator]
    #
    def initialize(params)
      @elements = params[:elements] ||= []
      @attributes = params[:attributes] ||= {} #{'a': ['href', 'target']}
      @attribute_value = params[:attribute_value] #{'style': "text-decoration: underline;"}
      @html = params[:html].to_s.strip
    end

    def perform
      nokogiri_html = Nokogiri::HTML.fragment(@html)

      if nokogiri_html.errors.length > 0
        noko_error = nokogiri_html.errors.first
        return noko_error.message.gsub("#{noko_error.line}:#{noko_error.column}: ERROR: ", "")
      else
        return trigger_function(nokogiri_html)
      end
      rescue
        "Error occurred while parsing."
    end


    def trigger_function(obj)

      if obj.class == Nokogiri::HTML::DocumentFragment
        return trigger_function(obj.children)

      elsif obj.class == Nokogiri::XML::Element
        return valid_element?(obj)

      elsif obj.class == Nokogiri::XML::Text
        return nil

      elsif obj.class == Nokogiri::XML::Attr
        invalid_attributes = get_invalid_attributes(obj.name, obj.attributes)
        if invalid_attributes.length > 0
          attribute_text = invalid_attributes.length == 1 ? "attribute" : "attributes"
          return "#{obj.name} tag has invalid #{attribute_text}: #{invalid_attributes.join(', ')}"
        end
        return nil

      elsif obj.class == Nokogiri::XML::NodeSet
        return valid_nodeset?(obj)
      end

      nil
    end

    def valid_nodeset?(node_set)
      node_set.each do |obj|
        error_text = trigger_function(obj)
        return error_text if error_text.present?
      end
      nil
    end

    def valid_element?(element)
      if @elements.include?(element.name)
        invalid_attributes = get_invalid_attributes(element.name, element.attributes)
        if invalid_attributes.length > 0
          attribute_text = invalid_attributes.length == 1 ? "attribute" : "attributes"
          return "#{element.name} Tag having extra #{attribute_text}: #{invalid_attributes.join(', ')}"
        else
          return "Invalid attribute value." if !valid_attribute_value?(element.attributes)
        end
        return element.children.present? ? trigger_function(element.children) : nil
      end

      "#{element.name} tag not allowed."
    end

    def valid_attribute_value?(attributes)
      attributes.each do |key, val|
        allowed_val = @attribute_value[key.to_sym]
        return false if allowed_val.present? && val.value.to_s.gsub(allowed_val,"").present?
      end
      true
    end

    def get_invalid_attributes(ele_name, ele_attributes)
      allowed_attributes = @attributes[ele_name.to_sym] || []
      (ele_attributes.keys - allowed_attributes)
    end

  end
end
