module AdminManagement

  module VerifyCookie

    class SingleAuth < AdminManagement::VerifyCookie::Base

      # Initialize
      #
      # * Author: Kedar
      # * Date: 10/10/2017
      # * Reviewed By: Sunil Khedar
      #
      # @params [String] cookie_value (mandatory) - this is the admin cookie value
      # @params [String] browser_user_agent (mandatory) - browser user agent
      #
      # @return [AdminManagement::VerifyCookie::SingleAuth]
      #
      def initialize(params)
        super
      end

      # Perform
      #
      # * Author: Kedar
      # * Date: 10/10/2017
      # * Reviewed By: Sunil Khedar
      #
      # @return [Result::Base]
      #
      def perform
        super
      end

      private

      # Auth level
      #
      # * Author: Kedar
      # * Date: 10/10/2017
      # * Reviewed By: Sunil Khedar
      #
      # @return [String]
      #
      def auth_level
        GlobalConstant::Cookie.single_auth_prefix
      end

      # Valid upto
      #
      # * Author: Kedar
      # * Date: 10/10/2017
      # * Reviewed By: Sunil Khedar
      #
      # @return [Time]
      #
      def valid_upto
        5.minute
      end

    end

  end

end