class AmlSearch < EstablishOstKycAmlDbConnection
  enum status: {
      GlobalConstant::AmlSearch.unprocessed_status => 1,
      GlobalConstant::AmlSearch.processed_status => 2,
      GlobalConstant::AmlSearch.failed_status => 3,
      GlobalConstant::AmlSearch.deleted_status => 4
  }

  MAX_RETRY_COUNT = 1

  scope :to_be_processed, -> {where(status: [GlobalConstant::AmlSearch.unprocessed_status,
                                             GlobalConstant::AmlSearch.failed_status]).where('retry_count <= ?', MAX_RETRY_COUNT)}

  after_commit :memcache_flush

  # Array Of Steps Done Taken By Aml
  #
  # * Author: Tejas
  # * Date: 10/01/2018
  # * Reviewed By:
  #
  # @returns [Array<Symbol>] returns Array of steps done bits set for aml
  #
  def steps_done_array
    @steps_done_array = AmlSearch.get_bits_set_for_steps_done(steps_done)
  end

  # Steps Done Config
  #
  # * Author: Tejas
  # * Date: 10/01/2018
  # * Reviewed By:
  #
  def self.steps_done_config
    @steps_done_con ||= {
        GlobalConstant::AmlSearch.search_step_done => 1,
        GlobalConstant::AmlSearch.pdf_step_done => 2
    }
  end

  # Bitwise columns config
  #
  # * Author: Tejas
  # * Date: 10/01/2018
  # * Reviewed By:
  #
  def self.bit_wise_columns_config
    @b_w_c_c ||= {
        steps_done: steps_done_config
    }
  end

  # Note : always include this after declaring bit_wise_columns_config method
  include BitWiseConcern

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