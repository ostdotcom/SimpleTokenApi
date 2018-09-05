module ClientManagement
  module PageSetting
    class Base < ServicesBase

      # Initialize
      #
      # * Author: Aman
      # * Date: 08/02/2018
      # * Reviewed By:
      #
      # @param [Integer] client_id (mandatory) -  client id
      #
      # @return [ClientManagement::PageSetting::Base]
      #
      def initialize(params)
        super

        @client_id = @params[:client_id]
        @entity_group_id = @params[:entity_group_id]

        @client = nil
        @group_entities = nil
        @common_theme_entity_obj = nil
        @entity_draft_obj = nil
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
        r = validate
        return r unless r.success?

        r = fetch_and_validate_client
        return r unless r.success?

        fetch_group_entities

        fetch_theme_entity

        fetch_current_page_entity_draft

        success_with_data(current_page_entity_response)
      end

      private

      # validate
      #
      # * Author: Aman
      # * Date: 08/02/2018
      # * Reviewed By:
      #
      # @return [Result::Base]
      #
      def validate
        r = super
        return r unless r.success?

        success
      end

      #  Fetch Group entities
      #
      # * Author: Pankaj
      # * Date: 16/08/2018
      # * Reviewed By:
      #
      # Sets @group_entities
      #
      def fetch_group_entities
        if @entity_group_id.to_i > 0
          @group_entities = EntityGroupDraft.get_group_entity_draft_ids_from_memcache(@entity_group_id)
        else
          fetch_client_published_entities
        end
      end

      #  Fetch client published entity drafts
      #
      # * Author: Pankaj
      # * Date: 10/08/2018
      # * Reviewed By:
      #
      # Sets @group_entities
      #
      def fetch_client_published_entities
        @group_entities = PublishedEntityGroup.fetch_published_draft_ids(@client_id)
      end

      #  Fetch theme entity from published entity
      #
      # * Author: Pankaj
      # * Date: 10/08/2018
      # * Reviewed By:
      #
      # Sets @common_theme_entity_obj
      #
      def fetch_theme_entity
        @common_theme_entity_obj = EntityDraft.get_entity_draft_from_memcache(@group_entities[GlobalConstant::EntityGroupDraft.theme_entity_type])
      end

      #  Fetch current page published entity
      #
      # * Author: Pankaj
      # * Date: 10/08/2018
      # * Reviewed By:
      #
      # Sets @entity_draft_obj
      #
      def fetch_current_page_entity_draft
        @entity_draft_obj = EntityDraft.get_entity_draft_from_memcache(@group_entities[page_entity_type])
      end


      # page entity type to fetch info for
      #
      # * Author: Pankaj
      # * Date: 13/08/2018
      # * Reviewed By:
      #
      def page_entity_type
        fail 'method not implemented page_entity_type'
      end

      # gives common_template_data_for_page
      #
      # * Author: Aman
      # * Date: 08/02/2018
      # * Reviewed By:
      #
      # @return [Hash] common template data
      #
      def common_data
        @common_theme_entity_obj.data
      end

      # gives template_data_for_page
      #
      # * Author: Aman
      # * Date: 08/02/2018
      # * Reviewed By:
      #
      # @return [Hash] template data for specific page
      #
      def page_data
        @entity_draft_obj.data
      end


      # Current page complete entity response
      #
      # * Author: Pankaj
      # * Date: 13/08/2018
      # * Reviewed By:
      #
      # @return [Hash]
      #
      def current_page_entity_response
        {
            common_data: common_data,
            page_data: page_data
        }
      end

    end
  end
end