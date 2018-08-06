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
      @elements = params[:elements] ||= ['html', 'p', 'body', 'a','i','br','b']
      @attributes = params[:attributes] ||= {'a': ['href','target']}
      @html = params[:html]
      @val = 0
    end

    def perform
      nokogiri_html = Nokogiri::HTML(@html)

      is_valid_html = valid_nokogiri?(nokogiri_html)

      puts "is_valid_html : #{is_valid_html}"
    end

    private

    def valid_nokogiri?(nokogiri_obj)
      puts "\nnokogiriobj: #{nokogiri_obj}"

      trigger_function(nokogiri_obj)
    end


    def trigger_function(nokogiri_obj)
      puts "val = #{@val}"
      @val +=1

      puts "trigger function for : #{nokogiri_obj}"
      if nokogiri_obj.class == Nokogiri::HTML::Document
        puts "\n NOKOGIRI_CLASS_DOCUMENT"
        return trigger_function(nokogiri_obj.children)

      elsif nokogiri_obj.class == Nokogiri::XML::DTD
        puts "\n NOKOGIRI_CLASS_DTD"
        return true

      elsif nokogiri_obj.class == Nokogiri::XML::Element
        puts "\n NOKOGIRI_CLASS_ELEMENT"
        return valid_nokogiri_element?(nokogiri_obj)

      elsif nokogiri_obj.class == Nokogiri::XML::Text
        puts "\n NOKOGIRI_CLASS_TEXT"
        return true

      elsif nokogiri_obj.class == Nokogiri::XML::Attr
        puts "\n NOKOGIRI_CLASS_ATTR"
        return valid_nokogiri_attr?(nokogiri_obj.name, nokogiri_obj.attributes)

      elsif nokogiri_obj.class == Nokogiri::XML::NodeSet
        puts "\n NOKOGIRI_CLASS_NODESET"
        return valid_nokogiri_nodeset?(nokogiri_obj.children)
      else
        puts "\nnokogiri class not found"
      end

      # case nokogiri_obj.class
      #   when Nokogiri::HTML::Document
      #     puts "\n NOKOGIRI_CLASS_DOCUMENT"
      #     return valid_nokogiri_nodeset?(nokogiri_obj.children)
      #
      #   when Nokogiri::XML::DTD
      #     puts "\n NOKOGIRI_CLASS_DTD"
      #     return true
      #
      #   when Nokogiri::XML::Element
      #     puts "\n NOKOGIRI_CLASS_ELEMENT"
      #     return valid_nokogiri_element?(nokogiri_obj)
      #
      #   when Nokogiri::XML::Text
      #     puts "\n NOKOGIRI_CLASS_TEXT"
      #     return true
      #
      #   when Nokogiri::XML::Attr
      #     puts "\n NOKOGIRI_CLASS_ATTR"
      #     return valid_nokogiri_attr?(nokogiri_obj.name, nokogiri_obj.attributes)
      #
      #   when Nokogiri::XML::NodeSet
      #     puts "\n NOKOGIRI_CLASS_NODESET"
      #     return valid_nokogiri_nodeset?(nokogiri_obj.children)
      #
      #   else
      #     puts "\nnokogiri class not found"
      # end
    end

    def valid_nokogiri_nodeset?(node_set)
      puts "node_set : #{node_set}"
      node_set.each_with_index do |obj, index|
        puts "node_set_obj : #{obj} and index : #{index}"
        is_success = trigger_function(obj)
        puts "is_success : #{is_success}"
        return false unless is_success
      end
      true
    end

    def valid_nokogiri_element?(element)
      puts "element : #{element}"
      if @elements.include?(element.name)
        return false if !valid_nokogiri_attr?(element.name, element.attributes)
        puts "triggering : #{element.children}"
        return trigger_function(element.children)
      end

      false
    end

    def valid_nokogiri_attr?(ele_name, attributes)
      ele_attributes = @attributes[ele_name.to_sym] || []
      puts "ele_name : #{ele_name} and attributes : #{attributes} and ele_attributes : #{ele_attributes}"

      ele_attributes == attributes.keys
    end

  end
end
