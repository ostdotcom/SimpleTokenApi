# frozen_string_literal: true
module GlobalConstant

  class Cookie

    class << self

      def admin_cookie_name
        'ta'
      end

      def user_cookie_name
        'tu'
      end

      def utm_cookie_name
        'st_utm'
      end

      def double_auth_expiry
        1.hour
      end

      def user_expiry
        5.minutes
      end

      def user_rotation
        2.minutes
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
