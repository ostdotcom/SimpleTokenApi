class AmlSearch < EstablishOstKycAmlDbConnection
  enum status: {
      GlobalConstant::AmlSearch.unprocessed_status => 1,
      GlobalConstant::AmlSearch.processed_status => 2,
      GlobalConstant::AmlSearch.failed_status => 3,
      GlobalConstant::AmlSearch.deleted_status => 4
  }

  enum steps_done: {
      GlobalConstant::AmlSearch.no_step_done => 1,
      GlobalConstant::AmlSearch.search_step_done => 2,
      GlobalConstant::AmlSearch.pdf_step_done => 3
  }

  after_commit :memcache_flush


  # Get Key Object
  #
  # * Author: Aman
  # * Date: 12/01/2019
  # * Reviewed By
  #
  # @return [MemcacheKey] Key Object
  #
  def self.get_memcache_key_object
    MemcacheKey.new('aml.aml_search')
  end

  # Get/Set Memcache data for Aml Search
  #
  # * Author: Aman
  # * Date: 12/01/2019
  # * Reviewed By
  #
  # @param [Integer] user_kyc_detail_id - user_kyc_detail_id
  # @param [Integer] user_extended_detail_id - user_extended_detail_id
  #
  # @return [AR] AmlSearch object
  #
  def self.get_from_memcache(user_kyc_detail_id, user_extended_detail_id)
    memcache_key_object = AmlSearch.get_memcache_key_object
    Memcache.get_set_memcached(memcache_key_object.key_template % {
        user_kyc_detail_id: user_kyc_detail_id,
        user_extended_detail_id: user_extended_detail_id
    }, memcache_key_object.expiry) do
      AmlSearch.where(user_kyc_detail_id: user_kyc_detail_id, user_extended_detail_id: user_extended_detail_id).first
    end
  end

  # Flush Memcache
  #
  # * Author: Aman
  # * Date: 12/01/2019
  # * Reviewed By
  #
  def memcache_flush
    memcache_key = AmlSearch.get_memcache_key_object.key_template % {
        user_kyc_detail_id: self.user_kyc_detail_id,
        user_extended_detail_id: self.user_extended_detail_id
    }
    Memcache.delete(memcache_key)
  end

end