class AdminActivityChangeLogger < EstablishSimpleTokenLogDbConnection

  TABLE_ALLOWED_KEYS_MAPPING = {
      GlobalConstant::AdminActivityChangeLogger.client_token_sale_details_table =>
          {val: 1, columns: ['token_symbol', 'token_name',  'ethereum_deposit_address']},
      GlobalConstant::AdminActivityChangeLogger.client_webhook_settings_table =>
          {val: 2, columns: ['secret_key', 'status',  'url', 'event_result_types', 'event_sources']}
  }.freeze

  enum source: {
      GlobalConstant::AdminActivityChangeLogger.script_source => 1,
      GlobalConstant::AdminActivityChangeLogger.web_source => 2
  }

  enum entity_type: begin
    entity_type_map = {}
    TABLE_ALLOWED_KEYS_MAPPING.each do |key, val|
      entity_type_map[key] = val[:val]
    end
    entity_type_map.freeze
  end

end