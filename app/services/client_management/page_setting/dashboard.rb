module ClientManagement
  module PageSetting

    class Dashboard < Base

      # Initialize
      #
      # * Author: Aman
      # * Date: 08/02/2018
      # * Reviewed By:
      #
      # @param [Integer] client_id (mandatory) -  client id
      #
      # @return [ClientManagement::PageSetting::Dashboard]
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

      # page entity type to fetch info for
      #
      # * Author: Pankaj
      # * Date: 13/08/2018
      # * Reviewed By:
      #
      def page_entity_type
        GlobalConstant::EntityGroupDraft.dashboard_entity_type
      end

    end
  end
end