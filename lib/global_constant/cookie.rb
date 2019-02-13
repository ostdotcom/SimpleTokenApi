# frozen_string_literal: true
module GlobalConstant

  class Cookie

    class << self

      def admin_cookie_name
        'ta'
      end

      def mfa_session_cookie_name
        'tm'
      end

      def user_cookie_name
        'tu'
      end

      def utm_cookie_name
        'ost_utm'
      end

      def double_auth_expiry
        # set max value
        GlobalConstant::AdminSessionSetting.max_session_inactivity_timeout.hours
      end

      def mfa_session_expiry
        30.days
      end

      def user_expiry
        30.minutes
      end

      def single_auth_expiry
        5.minute
      end

      def single_auth_prefix
        's'
      end

      def double_auth_prefix
        'd'
      end

    end

  end

end
