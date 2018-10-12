class ClientWebhookSetting < EstablishSimpleTokenClientDbConnection

  enum status: {
      GlobalConstant::ClientWebhookSetting.active_status => 1,
      GlobalConstant::ClientWebhookSetting.inactive_status => 2,
      GlobalConstant::ClientWebhookSetting.deleted_status => 3
  }

  # Array of event result types
  #
  # * Author: Aman
  # * Date: 12/10/2018
  # * Reviewed By:
  #
  # @returns [Array<Symbol>] returns Array of event result types bits set for Client Webhook Settings
  #
  def event_result_types_array
    @event_result_types_array = ClientWebhookSetting.get_bits_set_for_event_result_types(event_result_types)
  end

  # event result types config
  #
  # * Author: Aman
  # * Date: 12/10/2018
  # * Reviewed By:
  #
  def self.event_result_types_config
    @e_r_types_config ||= {
        GlobalConstant::Event.user_result_type => 1,
        GlobalConstant::Event.user_kyc_result_type => 2
    }
  end

  # Array of event sources
  #
  # * Author: Aman
  # * Date: 12/10/2018
  # * Reviewed By:
  #
  # @returns [Array<Symbol>] returns Array of event sources bits set for Client Webhook Settings
  #
  def event_sources_array
    @event_sources_array = ClientWebhookSetting.get_bits_set_for_event_sources(event_sources)
  end

  # event sources config
  #
  # * Author: Aman
  # * Date: 12/10/2018
  # * Reviewed By:
  #
  def self.event_sources_config
    @e_sources_config ||= {
        GlobalConstant::Event.web_source => 1,
        GlobalConstant::Event.api_source => 2,
        GlobalConstant::Event.system_source => 4
    }
  end

  # Bitwise columns config
  #
  # * Author: Aman
  # * Date: 12/10/2018
  # * Reviewed By:
  #
  def self.bit_wise_columns_config
    @b_w_c_c ||= {
        event_result_types: event_result_types_config,
        event_sources: event_sources_config
    }
  end

  # Note : always include this after declaring bit_wise_columns_config method
  include BitWiseConcern


end
