class Client < EstablishSimpleTokenClientDbConnection

  enum status: {
           GlobalConstant::Client.active_status => 1,
           GlobalConstant::Client.inactive_status => 2
       }

  after_commit :memcache_flush

  # Check if email setup is done for client
  #
  # * Author: Aman
  # * Date: 26/12/2017
  # * Reviewed By:
  #
  # @returns [Boolean] returns true if email setup is done for client
  #
  def is_email_setup_done?
    setup_properties_array.include?(GlobalConstant::Client.email_setup_done)
  end

  # Check if whitelisting setup is done for client
  #
  # * Author: Aman
  # * Date: 26/12/2017
  # * Reviewed By:
  #
  # @returns [Boolean] returns true if whitelisting setup is done for client
  #
  def is_whitelist_setup_done?
    setup_properties_array.include?(GlobalConstant::Client.whitelist_setup_done)
  end

  # Check if client is the internal st token sale client
  #
  # * Author: Aman
  # * Date: 26/12/2017
  # * Reviewed By:
  #
  # @returns [Boolean] returns true if client is the internal st token sale client
  #
  def is_st_token_sale_client?
    GlobalConstant::TokenSale.st_token_sale_client_id == self.id
  end

  # Array of Properties symbols
  #
  # * Author: Aman
  # * Date: 26/10/2017
  # * Reviewed By:
  #
  # @returns [Array<Symbol>] returns Array of setup properties bits set for client
  #
  def setup_properties_array
    @setup_properties_array = Client.get_bits_set_for_setup_properties(setup_properties)
  end

  # setup properties config
  #
  # * Author: Aman
  # * Date: 26/10/2017
  # * Reviewed By:
  #
  def self.setup_properties_config
    @setup_properties_config ||= {
        GlobalConstant::Client.cynopsis_setup_done => 1,
        GlobalConstant::Client.email_setup_done => 2,
        GlobalConstant::Client.whitelist_setup_done => 4
    }
  end

  # Bitwise columns config
  #
  # * Author: Aman
  # * Date: 26/10/2017
  # * Reviewed By:
  #
  def self.bit_wise_columns_config
    @b_w_c_c ||= {
        setup_properties: setup_properties_config
    }
  end

  # Note : always include this after declaring bit_wise_columns_config method
  include BitWiseConcern

  # Get Key Object
  #
  # * Author: Aman
  # * Date: 26/12/2017
  # * Reviewed By
  #
  # @return [MemcacheKey] Key Object
  #
  def self.get_memcache_key_object
    MemcacheKey.new('client.client_details')
  end

  # Get/Set Memcache data for User
  #
  # * Author: Aman
  # * Date: 26/12/2017
  # * Reviewed By
  #
  # @param [Integer] client_id - client id
  #
  # @return [AR] Client object
  #
  def self.get_from_memcache(client_id)
    memcache_key_object = Client.get_memcache_key_object
    Memcache.get_set_memcached(memcache_key_object.key_template % {id: client_id}, memcache_key_object.expiry) do
      Client.where(id: client_id).first
    end
  end

  private

  # Flush Memcache
  #
  # * Author: Aman
  # * Date: 26/12/2017
  # * Reviewed By
  #
  def memcache_flush
    client_memcache_key = Client.get_memcache_key_object.key_template % {id: self.id}
    Memcache.delete(client_memcache_key)
  end

end