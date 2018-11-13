class Client < EstablishSimpleTokenClientDbConnection

  enum status: {
           GlobalConstant::Client.active_status => 1,
           GlobalConstant::Client.inactive_status => 2
       }

  OST_KYC_CLIENT_IDENTIFIER = -1

  attr_accessor :decrypted_api_salt

  after_commit :memcache_flush

  # Check if whitelisting setup is done for client
  #
  # * Author: Aman
  # * Date: 01/02/2018
  # * Reviewed By:
  #
  # @returns [Boolean] returns true if whitelisting setup is done for client
  #
  def is_web_host_setup_done?
    setup_properties_array.include?(GlobalConstant::Client.web_host_setup_done)
  end

  # Check if verify page is needed after signup
  #
  # * Author: Aman
  # * Date: 27/04/2018
  # * Reviewed By:
  #
  # @returns [Boolean] returns true if verify page is needed
  #
  def is_verify_page_active_for_client?
    setup_properties_array.include?(GlobalConstant::Client.double_opt_in_setup_needed)
  end

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

  # send the web host domain of kyc clients if front end solution has been taken
  #
  # * Author: Aman
  # * Date: 13/11/2018
  # * Reviewed By:
  #
  # @return [Hash]
  #
  def web_host_params
    return {} if !is_web_host_setup_done?
    cwd = ClientWebHostDetail.get_from_memcache_by_client_id(self.id)

    {
        web_host_domain: cwd.domain
    }
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
        GlobalConstant::Client.aml_setup_done => 1,
        GlobalConstant::Client.email_setup_done => 2,
        GlobalConstant::Client.whitelist_setup_done => 4,
        GlobalConstant::Client.web_host_setup_done => 8,
        GlobalConstant::Client.double_opt_in_setup_needed => 16
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

  # Get/Set Memcache data for Client from Id
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

  # Get/Set Memcache data for Client from api key
  #
  # * Author: Aman
  # * Date: 26/12/2017
  # * Reviewed By
  #
  # @param [Integer] api_key - client api_key
  #
  # @return [AR] Client object
  #
  def self.get_client_for_api_key_from_memcache(api_key)
    api_memcache_key_object = MemcacheKey.new('client.api_key_details')
    Memcache.get_set_memcached(api_memcache_key_object.key_template % {api_key: api_key}, api_memcache_key_object.expiry) do
      client_obj = Client.where(api_key: api_key).first

      return nil if client_obj.blank?

      r = Aws::Kms.new('saas', 'saas').decrypt(client_obj.api_salt)
      client_obj.decrypted_api_salt = r.data[:plaintext] if  r.success?

      client_obj
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
    ClientSetting.flush_client_settings_cache(self.id)

    client_memcache_key = Client.get_memcache_key_object.key_template % {id: self.id}
    Memcache.delete(client_memcache_key)

    if self.previous_changes["api_key"].present?
      old_api_key = self.previous_changes["api_key"].first
      old_api_memcache_key = MemcacheKey.new('client.api_key_details').key_template % {api_key: old_api_key}
      Memcache.delete(old_api_memcache_key)
    end

    api_memcache_key = MemcacheKey.new('client.api_key_details').key_template % {api_key: self.api_key}
    Memcache.delete(api_memcache_key)
  end

end