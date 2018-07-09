class ClientKycAutoApproveSetting < EstablishSimpleTokenClientDbConnection

  enum status: {
      GlobalConstant::ClientKycAutoApproveSetting.active_status => 1,
      GlobalConstant::ClientKycAutoApproveSetting.inactive_status => 2
  }

  after_commit :memcache_flush

  # Array of ocr_comparison_fields values
  #
  # * Author: Aniket
  # * Date: 09/07/2018
  # * Reviewed By:
  #
  # @returns [Array<Symbol>] returns Array of ocr comparison fields bits set for client
  #
  def ocr_comparison_fields_array
    @ocr_comparison_fields_array = ClientKycAutoApproveSetting.get_bits_set_for_ocr_comparison_fields(ocr_comparison_fields)
  end

  # OCR comparison fields config
  #
  # * Author: Pankaj
  # * Date: 02/07/2018
  # * Reviewed By:
  #
  def self.ocr_comparison_fields_config
    @ocr_col_con ||= {
        GlobalConstant::ClientKycAutoApproveSetting.first_name_ocr_comparison_field => 1,
        GlobalConstant::ClientKycAutoApproveSetting.last_name_ocr_comparison_field => 2,
        GlobalConstant::ClientKycAutoApproveSetting.document_id_number_ocr_comparison_field => 4,
        GlobalConstant::ClientKycAutoApproveSetting.nationality_ocr_comparison_field => 8,
        GlobalConstant::ClientKycAutoApproveSetting.birthdate_ocr_comparison_field => 16
    }
  end

  # Bitwise columns config
  #
  # * Author: Pankaj
  # * Date: 02/07/2018
  # * Reviewed By:
  #
  def self.bit_wise_columns_config
    @b_w_c_c ||= {
        ocr_comparison_fields: ocr_comparison_fields_config
    }
  end

  # Note : always include this after declaring bit_wise_columns_config method
  include BitWiseConcern

  # Get Key Object
  #
  # * Author: Aniket
  # * Date: 03/07/2018
  # * Reviewed By: Aman
  #
  # @return [MemcacheKey] Key Object
  #
  def self.get_memcache_key_object
    MemcacheKey.new('client.client_kyc_auto_approve_active_setting')
  end

  # Get/Set Active Memcache data for Client
  #
  # * Author: Aniket
  # * Date: 03/07/2018
  # * Reviewed By: Aman
  #
  # @param [Integer] client_id - client id
  #
  # @return [AR] ClientKycAutoApproveSetting object
  #
  def self.get_active_setting_from_memcache(client_id)
    memcache_key_object = ClientKycAutoApproveSetting.get_memcache_key_object
    Memcache.get_set_memcached(memcache_key_object.key_template % {client_id: client_id}, memcache_key_object.expiry) do
      ClientKycAutoApproveSetting.where(client_id: client_id, status: GlobalConstant::ClientKycAutoApproveSetting.active_status).first
    end
  end

  # Flush Memcache
  #
  # * Author: Aniket/Tejas
  # * Date: 03/07/2018
  # * Reviewed By: Aman
  #
  def memcache_flush
    client_memcache_key = ClientKycAutoApproveSetting.get_memcache_key_object.key_template % {client_id: self.client_id}
    Memcache.delete(client_memcache_key)
  end
end
