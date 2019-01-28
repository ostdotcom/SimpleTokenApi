class AmlSearch < EstablishOstKycAmlDbConnection

  module Methods
    extend ActiveSupport::Concern

    included do

      MAX_RETRY_COUNT = 1

      enum status: {
          GlobalConstant::AmlSearch.unprocessed_status => 1,
          GlobalConstant::AmlSearch.processed_status => 2,
          GlobalConstant::AmlSearch.failed_status => 3,
          GlobalConstant::AmlSearch.deleted_status => 4
      }

      scope :to_be_processed, -> {where(status: [GlobalConstant::AmlSearch.unprocessed_status,
                                                 GlobalConstant::AmlSearch.failed_status]).
          where('retry_count <= ?', MAX_RETRY_COUNT)}

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
        @steps_done_array = self.singleton_class.get_bits_set_for_steps_done(steps_done)
      end

      # Flush Memcache
      #
      # * Author: Aman
      # * Date: 12/01/2019
      # * Reviewed By
      #
      def memcache_flush
        memcache_key = self.singleton_class.get_memcache_key_object.key_template % {
            shard_identifier: self.singleton_class.shard_identifier,
            user_kyc_detail_id: self.user_kyc_detail_id,
            user_extended_detail_id: self.user_extended_detail_id
        }
        Memcache.delete(memcache_key)
      end


      # Note : always include this after declaring bit_wise_columns_config method
      include BitWiseConcern
    end

    module ClassMethods

      # Steps Done Config
      #
      # * Author: Tejas
      # * Date: 10/01/2018
      # * Reviewed By:
      #
      def steps_done_config
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
      def bit_wise_columns_config
        @b_w_c_c ||= {
            steps_done: steps_done_config
        }
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
      def get_from_memcache(user_kyc_detail_id, user_extended_detail_id)
        memcache_key_object = self.get_memcache_key_object
        Memcache.get_set_memcached(memcache_key_object.key_template % {
            shard_identifier: self.shard_identifier,
            user_kyc_detail_id: user_kyc_detail_id,
            user_extended_detail_id: user_extended_detail_id
        }, memcache_key_object.expiry) do
          self.where(user_kyc_detail_id: user_kyc_detail_id, user_extended_detail_id: user_extended_detail_id).first
        end
      end

    end
  end


end