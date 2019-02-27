class AdminActivityChangeLogger < EstablishSimpleTokenLogDbConnection

  TABLE_ALLOWED_KEYS_MAPPING = {
      GlobalConstant::AdminActivityChangeLogger.client_token_sale_details_table =>
          {val: 1, skip_log_on_create: false,
           columns: ['token_symbol', 'token_name',  'ethereum_deposit_address', 'sale_start_timestamp', 'registration_end_timestamp', 'sale_end_timestamp']},
      GlobalConstant::AdminActivityChangeLogger.client_webhook_settings_table =>
          {val: 2, skip_log_on_create: false,
           columns: ['secret_key', 'status',  'url', 'event_result_types', 'event_sources']},
      GlobalConstant::AdminActivityChangeLogger.client_kyc_detail_api_activations_table =>
          {val: 3, skip_log_on_create: false,
           columns: ['kyc_fields','extra_kyc_fields']},
      GlobalConstant::AdminActivityChangeLogger.admin_session_setting_table =>
          {val: 4, skip_log_on_create: false,
           columns: ['admin_types','session_inactivity_timeout','status','mfa_frequency']},
      GlobalConstant::AdminActivityChangeLogger.client_kyc_config_details_table =>
          {val: 5, skip_log_on_create: false,
           columns: ['kyc_fields','extra_kyc_fields', 'residency_proof_nationalities', 'blacklisted_countries']},
      GlobalConstant::AdminActivityChangeLogger.client_whitelist_details_table =>
          {val: 6, skip_log_on_create: false,
           columns: ['contract_address','whitelister_address', 'version_id']}

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