class ClientKycDetailApiActivation < EstablishSimpleTokenClientDbConnection

  include ActivityChangeObserver

  serialize :extra_kyc_fields, Array

  enum status: {
      GlobalConstant::ClientKycDetailApiActivation.inactive_status => 0,
      GlobalConstant::ClientKycDetailApiActivation.active_status => 1,
  }


  after_commit :memcache_flush

  # Array of allowed keys for kyc form
  #
  # * Author: Tejas
  # * Date: 25/09/2018
  # * Reviewed By:
  #
  # @returns [Array<Symbol>] returns Array of allowed keys bits set for client's kyc form
  #
  def kyc_fields_array
    @kyc_fields_array = ClientKycDetailApiActivation.get_bits_set_for_kyc_fields(kyc_fields)
  end

  # allowed keys
  #
  # * Author: Tejas
  # * Date: 25/09/2018
  # * Reviewed By:
  #
  def self.kyc_fields
    ClientKycConfigDetail.kyc_fields_config
  end


  # Bitwise columns config
  #
  # * Author: Tejas
  # * Date: 25/09/2018
  # * Reviewed By:
  #
  def self.bit_wise_columns_config
    @b_w_c_c ||= {
        kyc_fields: kyc_fields
    }
  end

  # Note : always include this after declaring bit_wise_columns_config method
  include BitWiseConcern

  # Get Key Object
  #
  # * Author: Aman
  # * Date: 08/02/2018
  # * Reviewed By:
  #
  # @return [MemcacheKey] Key Object
  #
  def self.get_memcache_key_object
    MemcacheKey.new('client.client_kyc_detail_api_activations')
  end


  # Get/Set Memcache last active data for clients kyc details api activation
  #
  # * Author: Aman
  # * Date: 08/02/2018
  # * Reviewed By:
  #
  # @param [Integer] client_id - client id
  #
  # @return [AR] ClientKycDetailApiActivation object
  #
  def self.get_last_active_from_memcache(client_id)
    memcache_key_object = ClientKycDetailApiActivation.get_memcache_key_object
    Memcache.get_set_memcached(memcache_key_object.key_template % {client_id: client_id}, memcache_key_object.expiry) do
      ClientKycDetailApiActivation.where(client_id: client_id, status: GlobalConstant::ClientKycDetailApiActivation.active_status).last
    end
  end

  private

  # Flush Memcache
  #
  # * Author: Aman
  # * Date: 08/02/2018
  # * Reviewed By:
  #
  def memcache_flush
    client_kyc_detail_api_activations_memcache_key = ClientKycDetailApiActivation.get_memcache_key_object.key_template % {client_id: self.client_id}
    Memcache.delete(client_kyc_detail_api_activations_memcache_key)
  end

end
