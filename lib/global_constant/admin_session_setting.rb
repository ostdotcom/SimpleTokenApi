module GlobalConstant
  class AdminSessionSetting
    class << self

      ### Status Start ###

      def active_status
        'active'
      end

      def deleted_status
        'deleted'
      end

      ### Status End ###

      def default_session_inactivity_timeout
        1.hour.to_i
      end

      def default_mfa_frequency
        0.days.to_i
      end

      def min_session_inactivity_timeout
        1.to_i
      end

      def max_session_inactivity_timeout
        3.to_i
      end

      def max_mfa_frequency_value
        14.to_i
      end

    end
  end
end