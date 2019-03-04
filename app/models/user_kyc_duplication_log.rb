class UserKycDuplicationLog

  module Methods
    extend ActiveSupport::Concern
    included do

      enum status: {
          GlobalConstant::UserKycDuplicationLog.active_status => 1,
          GlobalConstant::UserKycDuplicationLog.inactive_status => 2,
          GlobalConstant::UserKycDuplicationLog.deleted_status => 3
      }

      enum duplicate_type: {
          GlobalConstant::UserKycDuplicationLog.document_id_with_country_duplicate_type => 1,
          GlobalConstant::UserKycDuplicationLog.ethereum_duplicate_type => 2,
          GlobalConstant::UserKycDuplicationLog.only_document_id_duplicate_type => 3,
          GlobalConstant::UserKycDuplicationLog.address_duplicate_type => 4
      }

      scope :active_ethereum_duplicates, -> {
        where(duplicate_type: GlobalConstant::UserKycDuplicationLog.ethereum_duplicate_type).active
      }

      scope :non_deleted, -> {
        where(status: [GlobalConstant::UserKycDuplicationLog.active_status, GlobalConstant::UserKycDuplicationLog.inactive_status])
      }


    end

    module ClassMethods

      def bulk_insert(new_duplicate_log_rows)

        logs_sql = "INSERT INTO `user_kyc_duplication_logs` (`user1_id`, `user2_id`, `user_extended_details1_id`, `user_extended_details2_id`,`duplicate_type`,`status`,`created_at`, `updated_at`)" +
            "VALUES #{new_duplicate_log_rows.join(', ')} ;"

        self.connection.execute(logs_sql)

      end

    end
  end


end
