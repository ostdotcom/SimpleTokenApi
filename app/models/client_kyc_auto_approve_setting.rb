class ClientKycAutoApproveSetting < EstablishSimpleTokenClientDbConnection

  enum status: {
      GlobalConstant::ClientKycAutoApproveSettings.active_status => 1,
      GlobalConstant::ClientKycAutoApproveSettings.inactive_status => 2
  }

  after_commit :memcache_flush

  # OCR comparison columns config
  #
  # * Author: Pankaj
  # * Date: 02/07/2018
  # * Reviewed By:
  #
  def self.ocr_comparison_columns_config
    @ocr_col_con ||= {
        GlobalConstant::ClientKycAutoApproveSettings.first_name_ocr_comparison_column => 1,
        GlobalConstant::ClientKycAutoApproveSettings.last_name_ocr_comparison_column => 2,
        GlobalConstant::ClientKycAutoApproveSettings.document_id_ocr_comparison_column => 4,
        GlobalConstant::ClientKycAutoApproveSettings.nationality_ocr_comparison_column => 8,
        GlobalConstant::ClientKycAutoApproveSettings.birthdate_ocr_comparison_column => 16
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
        ocr_comparison_columns: ocr_comparison_columns_config
    }
  end

  # Note : always include this after declaring bit_wise_columns_config method
  include BitWiseConcern


  # Get Key Object
  #
  # * Author: Aniket
  # * Date: 03/07/2018
  # * Reviewed By
  #
  # @return [MemcacheKey] Key Object
  #
  def self.get_memcache_key_object
    MemcacheKey.new('client.client_kyc_auto_approve_setting')
  end

  # Get/Set Memcache data for Client from Id
  #
  # * Author: Aniket
  # * Date: 03/07/2018
  # * Reviewed By
  #
  # @param [Integer] client_id - client id
  #
  # @return [AR] Client object
  #
  def self.get_from_memcache(client_id)
    memcache_key_object = ClientKycAutoApproveSetting.get_memcache_key_object
    Memcache.get_set_memcached(memcache_key_object.key_template % {client_id: client_id}, memcache_key_object.expiry) do
      ClientKycAutoApproveSetting.where(client_id: client_id, status: GlobalConstant::ClientKycAutoApproveSettings.active_status).first
    end
  end


  # Flush Memcache
  #
  # * Author: Aniket/Tejas
  # * Date: 03/07/2018
  # * Reviewed By
  #
  def memcache_flush
    client_memcache_key = ClientKycAutoApproveSetting.get_memcache_key_object.key_template % {client_id: self.id}
    Memcache.delete(client_memcache_key)

  end
end
