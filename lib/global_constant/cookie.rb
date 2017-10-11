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

      def default_expiry
        1.day
      end

    end

  end

end
