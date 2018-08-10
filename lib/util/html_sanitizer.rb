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

      @elements |= ['html', 'p', 'body']
    end

    def perform
      nokogiri_html = Nokogiri::HTML(@html)
      is_valid_html = trigger_function(nokogiri_html)
      puts "is_valid_html : #{is_valid_html}"
      is_valid_html
    rescue
      puts "error occored while converting html"
      false
    end


    def trigger_function(obj)
      puts "\ntrigger function for : #{obj}"

      if obj.class == Nokogiri::HTML::Document
        puts "NOKOGIRI_CLASS_DOCUMENT"
        return trigger_function(obj.children)

      elsif obj.class == Nokogiri::XML::DTD
        puts "NOKOGIRI_CLASS_DTD \nreturning: true"
        return true

      elsif obj.class == Nokogiri::XML::Element
        puts "NOKOGIRI_CLASS_ELEMENT"
        return valid_element?(obj)

      elsif obj.class == Nokogiri::XML::Text
        puts "NOKOGIRI_CLASS_TEXT \nreturning: true"
        return true

      elsif obj.class == Nokogiri::XML::Attr
        puts "NOKOGIRI_CLASS_ATTR"
        return valid_attr?(obj.name, obj.attributes)

      elsif obj.class == Nokogiri::XML::NodeSet
        puts "NOKOGIRI_CLASS_NODESET"
        return valid_nodeset?(obj)
      else
        puts "\nnokogiri class not found"
      end
    end

    def valid_nodeset?(node_set)
      puts "node_set : #{node_set}"
      node_set.each_with_index do |obj, index|
        puts "index : #{index} and obj : #{obj}"
        is_success = trigger_function(obj)
        if !is_success
          puts "returning false for #{obj}"
          return false
        end
      end
      true
    end

    def valid_element?(element)
      puts "element : #{element} and class: #{element.name}"
      if @elements.include?(element.name)
        if !valid_attributes?(element.name, element.attributes)
          puts "returning false because attributes didn't match"
          return false
        end
        puts "triggering : #{element.children}"
        return trigger_function(element.children)
      end
      puts "element //#{element.name}// not allowed"
      false
    end

    def valid_attributes?(ele_name, attributes)
      ele_attributes = @attributes[ele_name.to_sym] || []
      puts "ele_name : #{ele_name}\nelement_attributes : #{attributes.keys}\nattributes_required: #{ele_attributes}"

      (ele_attributes - attributes.keys).length == 0
    end

  end
end
