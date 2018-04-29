module ClientManagement
  module PageSetting

    class Verification < Base

      # Initialize
      #
      # * Author: Aman
      # * Date: 08/02/2018
      # * Reviewed By:
      #
      # @param [Integer] client_id (mandatory) -  client id
      #
      # @return [ClientManagement::PageSetting::Verification]
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
        #todo: VERIFYPAGE change it to verification template type with migrations for all client using it
        GlobalConstant::ClientTemplate.change_password_template_type
      end

    end
  end
end