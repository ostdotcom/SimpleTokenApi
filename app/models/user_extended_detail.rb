class UserExtendedDetail

  module Methods
    extend ActiveSupport::Concern

    included do

      after_commit :memcache_flush

      # Flush Memcache
      #
      # * Author: Tejas
      # * Date: 27/09/2018
      # * Reviewed By:
      #
      def get_full_name
        (self.first_name + " " + self.last_name).titleize
      end

      # Flush Memcache
      #
      # * Author: Tejas
      # * Date: 27/09/2018
      # * Reviewed By:
      #
      def memcache_flush
        user_extended_detail_memcache_key = self.singleton_class.get_memcache_key_object.key_template % {
            id: self.id,
            shard_identifier: self.singleton_class.shard_identifier
        }
        Memcache.delete(user_extended_detail_memcache_key)
      end
    end


    module ClassMethods

      # Check if Duplicate KYC Approved User
      #
      # * Author: Abhay
      # * Date: 30/10/2017
      # * Reviewed By: Sunil
      #
      # return [Bool] true/false
      #
      def is_duplicate_kyc_approved_user?(client_id, user_extended_detail_id)
        u_e_d = self.where(id: user_extended_detail_id).first

        hashed_nationality = Util::Encryption::Admin.get_sha256_hashed_value_from_kms_encrypted_value(u_e_d.kyc_salt, u_e_d.nationality)
        hashed_document_id_number = Util::Encryption::Admin.get_sha256_hashed_value_from_kms_encrypted_value(u_e_d.kyc_salt, u_e_d.document_id_number)

        where_clause = '(document_id_number = ? && nationality = ?)'
        where_clause_values = [hashed_document_id_number, hashed_nationality]

        if u_e_d.ethereum_address.present?
          hashed_ethereurm_address = Util::Encryption::Admin.get_sha256_hashed_value_from_kms_encrypted_value(u_e_d.kyc_salt, u_e_d.ethereum_address)
          where_clause += 'or (ethereum_address = ?)'
          where_clause_values << hashed_ethereurm_address
        end

        user_extended_detail_ids = Md5UserExtendedDetail.using_shard(shard_identifier: self.shard_identifier).
            where([where_clause] + where_clause_values).
            pluck(:user_extended_detail_id)

        user_extended_detail_ids.delete(user_extended_detail_id)
        return false if user_extended_detail_ids.blank?
        UserKycDetail.using_shard(shard_identifier: self.shard_identifier).
            active_kyc.where(client_id: client_id,
                             user_extended_detail_id: user_extended_detail_ids,
                             admin_status: GlobalConstant::UserKycDetail.admin_approved_statuses).exists?
      end

      # Get Key Object
      #
      # * Author: Tejas
      # * Date: 27/09/2018
      # * Reviewed By:
      #
      # @return [MemcacheKey] Key Object
      #
      def get_memcache_key_object
        MemcacheKey.new('user.user_extended_detail')
      end

      # Get/Set Memcache data for UserExtendedDetail
      #
      # * Author: Tejas
      # * Date: 27/09/2018
      # * Reviewed By:
      #
      # @param [Integer] user_id - user id
      #
      # @return [AR] UserExtendedDetail object
      #
      def get_from_memcache(id)
        memcache_key_object = self.get_memcache_key_object
        Memcache.get_set_memcached(memcache_key_object.key_template % {
            id: id,
            shard_identifier: self.shard_identifier
        }, memcache_key_object.expiry) do
          self.where(id: id).first
        end
      end

    end

  end

end
