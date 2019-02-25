class EscapeHtmlFields

    include ::Util::ResultHelper

    # Initialize
    #
    # * Author: Aniket
    # * Date: 28/04/2018
    # * Reviewed By:
    #
    # @params [String] entity_type (mandatory) - entity type
    # @params [Hash] params (mandatory) - params
    #
    # Sets @entity_config, @params[:form_data]
    #
    #
    def initialize(params)
      @entity_type = params["entity_type"]
      @params = params
      @params[:form_data] = {}
      @entity_config = nil
    end

    # Perform
    #
    # * Author: Aniket
    # * Date: 28/04/2018
    # * Reviewed By:
    #
    def perform
      return if GlobalConstant::EntityGroupDraft.allowed_entity_types_from_fe.exclude?(@entity_type)

      fetch_entity_config
      merge_dynamic_config

      escape_html_fields
    end

    private

    # Fetch entity config
    #
    # * Author: Aniket
    # * Date: 28/04/2018
    # * Reviewed By:
    #
    def fetch_entity_config
      @entity_config = GlobalConstant::CmsConfigurator.get_entity_config(@entity_type)
    end

    # Escape html fields from Sanitize
    #
    # * Author: Aniket
    # * Date: 28/04/2018
    # * Reviewed By:
    #
    def escape_html_fields
      @entity_config.each do |key, entity_config|
        entity_val = @params[key.to_sym]
        next if entity_val.blank?
        r = escape_html_fields_recursively(entity_val, entity_config)
        @params[:form_data][key.to_sym] = r
        @params.delete(key)
      end
    end

    # Get escaped fields for data_type html
    #
    # * Author: Aniket
    # * Date: 28/04/2018
    # * Reviewed By:
    #
    def escape_html_fields_recursively(entity_val, entity_config)
      entity_config = entity_config || {}
      sanitized_val = nil

      if entity_val.is_a?(String)
        data_kind = entity_config[GlobalConstant::CmsConfigurator.data_kind_key]
        if data_kind == GlobalConstant::CmsConfigurator.value_html
          sanitized_val = CGI.escapeHTML(entity_val)
        else
          sanitized_val = entity_val
        end

      elsif entity_val.is_a?(Hash) || entity_val.is_a?(ActionController::Parameters)
        sanitized_val = {}
        entity_val.each do |key, val|
          r = escape_html_fields_recursively(val, entity_config[key])
          sanitized_val[key.to_sym] = r

        end
      elsif entity_val.is_a?(Array)
        sanitized_val =[]

        entity_val.each_with_index do |val, index|
          r = escape_html_fields_recursively(val, entity_config[GlobalConstant::CmsConfigurator.element_key])
          sanitized_val << r
        end
      end
      sanitized_val
    end

    # Get escaped fields for extra_kyc_fields instruction text keys
    #
    # * Author: Aniket
    # * Date: 28/04/2018
    # * Reviewed By:
    #
  def merge_dynamic_config
    return if GlobalConstant::EntityGroupDraft.kyc_entity_type != @entity_type
    field_config = GlobalConstant::CmsConfigurator.extra_kyc_field_instruction_text_config

    @params.keys.each do |x|
      @entity_config[x.to_s] = field_config if x.to_s.ends_with?(
          GlobalConstant::CmsConfigurator.extra_kyc_field_instruction_key_suffix)
    end

  end

end
