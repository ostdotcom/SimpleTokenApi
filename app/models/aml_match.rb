class AmlMatch < EstablishOstKycAmlDbConnection

  module Methods
    extend ActiveSupport::Concern
    included do

      enum status: {
          GlobalConstant::AmlMatch.unprocessed_status => 1,
          GlobalConstant::AmlMatch.match_status => 2,
          GlobalConstant::AmlMatch.no_match_status => 3
      }

      after_commit :memcache_flush

      # Flush Memcache
      #
      # * Author: Aman
      # * Date: 12/01/2019
      # * Reviewed By
      #
      def memcache_flush
        memcache_key = self.singleton_class.get_memcache_key_object.key_template % {
            shard_identifier: self.singleton_class.shard_identifier,
            aml_search_uuid: aml_search_uuid
        }
        Memcache.delete(memcache_key)
      end

    end

    module ClassMethods

      # Bulk Flush memcache
      #
      # * Author: Aman
      # * Date: 12/01/2019
      # * Reviewed By
      #
      # @return [MemcacheKey] Key Object
      #
      def bulk_flush_matches_memcache(aml_match_obj)
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
      def get_memcache_key_object
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
        memcache_key_object = self.get_memcache_key_object
        Memcache.get_set_memcached(memcache_key_object.key_template % {
            shard_identifier: self.shard_identifier,
            aml_search_uuid: aml_search_uuid
        },
                                   memcache_key_object.expiry) do
          AmlMatch.using_shard(shard_identifier: self.shard_identifier).
              where(aml_search_uuid: aml_search_uuid).order(:id).all
        end
      end

    end
  end

end
