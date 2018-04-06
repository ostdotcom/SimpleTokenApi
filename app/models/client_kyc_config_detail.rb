class ClientKycConfigDetail < EstablishSimpleTokenClientDbConnection

  serialize :residency_proof_nationalities, Array

  after_commit :memcache_flush


  # Add kyc config row for client
  #
  # * Author: Aman
  # * Date: 08/02/2018
  # * Reviewed By:
  #
  def self.add_config(params)

    fail 'mandatory kyc fields missing' if !params[:kyc_fields].is_a?(Array) ||
        (GlobalConstant::ClientKycConfigDetail.mandatory_fields - params[:kyc_fields]).present?

    fail 'Invalid kyc fields' if (params[:kyc_fields] - ClientKycConfigDetail.kyc_fields_config.keys).present?

    fail 'Invalid residency_proof_nationalities' if !params[:residency_proof_nationalities].is_a?(Array) ||
        (params[:residency_proof_nationalities] - GlobalConstant::CountryNationality.nationalities).present?

    kyc_field_bit_value = 0

    params[:kyc_fields].each do |field_name|
      kyc_field_bit_value += ClientKycConfigDetail.kyc_fields_config[field_name]
    end

    ClientKycConfigDetail.create!(
        client_id: params[:client_id],
        kyc_fields: kyc_field_bit_value,
        residency_proof_nationalities: params[:residency_proof_nationalities]
    )

  end

  # Array of kyc fields for kyc form
  #
  # * Author: Aman
  # * Date: 08/02/2018
  # * Reviewed By:
  #
  # @returns [Array<Symbol>] returns Array of kyc fields bits set for client's kyc form
  #
  def kyc_fields_array
    @kyc_fields_array = ClientKycConfigDetail.get_bits_set_for_kyc_fields(kyc_fields)
  end

  # kyc fields config
  #
  # * Author: Aman
  # * Date: 08/02/2018
  # * Reviewed By:
  #
  def self.kyc_fields_config
    @kyc_fields_config ||= {
        GlobalConstant::ClientKycConfigDetail.first_name_kyc_field => 1,
        GlobalConstant::ClientKycConfigDetail.last_name_kyc_field => 2,
        GlobalConstant::ClientKycConfigDetail.dob_kyc_field => 4,
        GlobalConstant::ClientKycConfigDetail.stree_address_kyc_field => 8,
        GlobalConstant::ClientKycConfigDetail.city_kyc_field => 16,
        GlobalConstant::ClientKycConfigDetail.state_kyc_field => 32,
        GlobalConstant::ClientKycConfigDetail.country_kyc_field => 64,
        GlobalConstant::ClientKycConfigDetail.postal_code_kyc_field => 128,
        GlobalConstant::ClientKycConfigDetail.ethereum_address_kyc_field => 256,
        GlobalConstant::ClientKycConfigDetail.document_id_number_kyc_field => 512,
        GlobalConstant::ClientKycConfigDetail.nationality_kyc_field => 1024,
        GlobalConstant::ClientKycConfigDetail.document_id_file_path_kyc_field => 2048,
        GlobalConstant::ClientKycConfigDetail.selfie_file_path_kyc_field => 4096,
        GlobalConstant::ClientKycConfigDetail.residence_proof_file_path_kyc_field => 8192,
        GlobalConstant::ClientKycConfigDetail.estimated_participation_amount_kyc_field => 16384
    }
  end

  # Bitwise columns config
  #
  # * Author: Aman
  # * Date: 08/02/2018
  # * Reviewed By:
  #
  def self.bit_wise_columns_config
    @b_w_c_c ||= {
        kyc_fields: kyc_fields_config
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
    MemcacheKey.new('client.client_kyc_config_details')
  end

  # Get/Set Memcache data for clients kyc config details
  #
  # * Author: Aman
  # * Date: 08/02/2018
  # * Reviewed By:
  #
  # @param [Integer] client_id - client id
  #
  # @return [AR] ClientKycConfigDetail object
  #
  def self.get_from_memcache(client_id)
    memcache_key_object = ClientKycConfigDetail.get_memcache_key_object
    Memcache.get_set_memcached(memcache_key_object.key_template % {client_id: client_id}, memcache_key_object.expiry) do
      ClientKycConfigDetail.where(client_id: client_id).first
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
    client_kyc_config_details_memcache_key = ClientKycConfigDetail.get_memcache_key_object.key_template % {client_id: self.client_id}
    Memcache.delete(client_kyc_config_details_memcache_key)
  end

end