class ClientPlan < EstablishSimpleTokenBillingDbConnection

  after_commit :memcache_flush

  enum status: {
      GlobalConstant::ClientPlan.active_status => 1,
      GlobalConstant::ClientPlan.inactive_status => 2
  }

  enum notification_type: {
      GlobalConstant::ClientPlan.first_threshold_notification_type => 1,
      GlobalConstant::ClientPlan.second_threshold_notification_type => 2,
      GlobalConstant::ClientPlan.max_threshold_notification_type => 3
  }

  THRESHOLD_PERCENT = {
      GlobalConstant::ClientPlan.first_threshold_notification_type => GlobalConstant::ClientPlan.first_threshold_percent,
      GlobalConstant::ClientPlan.second_threshold_notification_type => GlobalConstant::ClientPlan.second_threshold_percent,
      GlobalConstant::ClientPlan.max_threshold_notification_type => GlobalConstant::ClientPlan.max_threshold_percent
  }

  # Array of add_ons taken by client
  #
  # * Author: Aman
  # * Date: 18/092018
  # * Reviewed By:
  #
  # @returns [Array<Symbol>] returns Array of add_ons bits set for client
  #
  def add_ons_array
    @add_ons_array = ClientPlan.get_bits_set_for_properties(add_ons)
  end

  # add_ons config
  #
  # * Author: Aman
  # * Date: 18/092018
  # * Reviewed By:
  #
  def self.add_ons_config
    @ap_add_ons_con ||= {
        GlobalConstant::ClientPlan.whitelist_add_ons => 1,
        GlobalConstant::ClientPlan.custom_front_end_add_ons => 2
    }
  end

  # Bitwise columns config
  #
  # * Author: Aman
  # * Date: 18/092018
  # * Reviewed By:
  #
  def self.bit_wise_columns_config
    @b_w_c_c ||= {
        add_ons: add_ons_config
    }
  end

  # Note : always include this after declaring bit_wise_columns_config method
  include BitWiseConcern

  # Get Key Object
  #
  # * Author: Aman
  # * Date: 18/09/2018
  # * Reviewed By:
  #
  # @return [MemcacheKey] Key Object
  #
  def self.get_memcache_key_object
    MemcacheKey.new('billing.client_plan')
  end

  # Get/Set Active Memcache data for client plan
  #
  # * Author: Aman
  # * Date: 18/09/2018
  # * Reviewed By:
  #
  # @param [Integer] client_id - client_id
  #
  # @return [AR] ClientPlan object
  #
  def self.get_client_plan_from_memcache(client_id)
    memcache_key_object = ClientPlan.get_memcache_key_object
    Memcache.get_set_memcached(memcache_key_object.key_template % {client_id: client_id}, memcache_key_object.expiry) do
      ClientPlan.where(client_id: client_id).first
    end
  end

  # Flush Memcache
  #
  # * Author: Aman
  # * Date: 18/09/2018
  # * Reviewed By:
  #
  def memcache_flush
    client_plan_memcache_key = ClientPlan.get_memcache_key_object.key_template % {client_id: self.client_id}
    Memcache.delete(client_plan_memcache_key)
  end

end
