class AmlMatch < EstablishOstKycAmlDbConnection
  enum status: {
      GlobalConstant::AmlMatch.unprocessed_status => 1,
      GlobalConstant::AmlMatch.match_status => 2,
      GlobalConstant::AmlMatch.no_match_status => 3
  }

  after_commit :memcache_flush



  # Bulk Flush memcache
  #
  # * Author: Aman
  # * Date: 12/01/2019
  # * Reviewed By
  #
  # @return [MemcacheKey] Key Object
  #
  def self.bulk_flush_matches_memcache(aml_match_obj)
    aml_match_obj.memcache_flush
  end

  # Get Key Object
  #
  # * Author: Aman
  # * Date: 12/01/2019
  # * Reviewed By
  #
  # @return [MemcacheKey] Key Object
  #
  def self.get_memcache_key_object
    MemcacheKey.new('aml.all_aml_match')
  end

  # Get/Set Memcache data for all Aml Matches of a search
  #
  # * Author: Aman
  # * Date: 12/01/2019
  # * Reviewed By
  #
  # @param [String] aml_search_uuid - aml_search_uuid
  #
  # @return [AR] AmlSearch object
  #
  def self.get_from_memcache(aml_search_uuid)
    memcache_key_object = AmlMatch.get_memcache_key_object
    Memcache.get_set_memcached(memcache_key_object.key_template % {aml_search_uuid: aml_search_uuid},
                               memcache_key_object.expiry) do
      AmlMatch.where(aml_search_uuid: aml_search_uuid).all
    end
  end

  # Flush Memcache
  #
  # * Author: Aman
  # * Date: 12/01/2019
  # * Reviewed By
  #
  def memcache_flush
    memcache_key = AmlMatch.get_memcache_key_object.key_template % {aml_search_uuid: aml_search_uuid}
    Memcache.delete(memcache_key)
  end

end
