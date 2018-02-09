module ClientManagement
  module PageSetting

    class Login < Base

      # Initialize
      #
      # * Author: Aman
      # * Date: 08/02/2018
      # * Reviewed By:
      #
      # @param [Integer] client_id (mandatory) -  client id
      #
      # @return [ClientManagement::PageSetting::Login]
      #
      def initialize(params)
        super
      end

      # Perform
      #
      # * Author: Aman
      # * Date: 08/02/2018
      # * Reviewed By:
      #
      # @return [Result::Base]
      #
      def perform
        super
      end

      private

      # page template type to fetch info for
      #
      # * Author: Aman
      # * Date: 08/02/2018
      # * Reviewed By:
      #
      def page_template_type
        GlobalConstant::ClientTemplate.login_template_type
      end

    end
  end
end