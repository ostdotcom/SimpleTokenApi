class UserEmailDuplicationLog

  module Methods
    extend ActiveSupport::Concern
    included do

      enum status: {
          GlobalConstant::UserEmailDuplicationLog.active_status => 1,
          GlobalConstant::UserEmailDuplicationLog.inactive_status => 2
      }


    end

    module ClassMethods

      def bulk_insert(new_email_duplicate_log_rows)

        logs_sql = "INSERT INTO `user_email_duplication_logs` (`user1_id`, `user2_id`, `status`,`created_at`, `updated_at`)" +
            "VALUES #{new_email_duplicate_log_rows.join(', ')} ;"

        self.connection.execute(logs_sql)
      end

    end
  end


end
