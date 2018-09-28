# frozen_string_literal: true
module GlobalConstant

  class KycWhitelistLog

    class << self

      ### Status Start ###

      def pending_status
        'pending'
      end

      def done_status
        'done'
      end

      def confirmed_status
        'confirmed'
      end

      def failed_status
        'failed'
      end

      ### Status End ###

      def kyc_whitelist_confirmation_pending_statuses
        [
            pending_status,
            done_status
        ]
      end

      ### Failed Reason starts ####

      def not_failed
        'not_failed'
      end

      def invalid_kyc_failed
        'invalid_kyc_failed'
      end

      def invalid_transaction_failed
        'invalid_transaction_failed'
      end

      def invalid_event_failed
        'invalid_event_failed'
      end

      ### Failed Reason ends ####

      ### transaction status ####

      def invalid_txn_status
        'invalid'
      end

      def pending_txn_status
        'pending'
      end

      def failed_txn_status
        'failed'
      end

      def mined_txn_status
        'mined'
      end

      def all_txn_statuses
        [invalid_txn_status, pending_txn_status, failed_txn_status, mined_txn_status]
      end

      ### Constants ###
      #
      def expected_transaction_mine_time
        3.minutes.to_i
      end

      def confirm_wait_interval
        90.seconds.to_i
      end

      def extreme_wait_interval
        30.minutes.to_i
      end

      def next_timestamp_increment_factor
        0.30
      end

    end

  end

end
