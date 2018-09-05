module AdminManagement

  module CmsConfigurator

    class GetPublishedDraft < ServicesBase

      # Initialize
      #
      # * Author: Tejas
      # * Date: 08/08/2018
      # * Reviewed By:
      #
      # @params [Integer] client_id (mandatory) - logged in admin's client id
      #
      # @return [AdminManagement::CmsConfigurator::GetPublishedDraft]
      #
      def initialize(params)
        super
        @client_id = @params[:client_id]

        @entity_type_and_data_hash = {}
      end

      # Perform
      #
      # * Author: Tejas
      # * Date: 08/08/2018
      # * Reviewed By:
      #
      # @return [Result::Base]
      #
      def perform

        r = validate
        return r unless r.success?

        r = get_published_draft
        return r unless r.success?

        success_with_data(success_response_data)

      end

      private

      # Validate
      #
      # * Author: Tejas
      # * Date: 14/08/2018
      # * Reviewed By:
      #
      # @return [Result::Base]
      #
      def validate
        r = super
        return r unless r.success?

        r = fetch_and_validate_client
        return r unless r.success?

        return error_with_data(
            'am_cc_gpd_v_1',
            'Client does not have a web host support',
            'Client does not have a web host support',
            GlobalConstant::ErrorAction.default,
            {}
        ) if !@client.is_web_host_setup_done?

        success
      end

      # Get Published Draft
      #
      # * Author: Tejas
      # * Date: 14/08/2018
      # * Reviewed By:
      #
      # Sets @entity_type_and_data_hash
      #
      def get_published_draft
        entity_draft_hash_for_gid = PublishedEntityGroup.fetch_published_draft_ids(@client_id)

        entity_draft_objs = EntityDraft.where(id: entity_draft_hash_for_gid.values).all.index_by(&:id)

        entity_draft_hash_for_gid.each do |key, draft_id|
          @entity_type_and_data_hash[key] = entity_draft_objs[draft_id].data
        end


        success
      end

      # Api response data
      #
      # * Author: Tejas
      # * Date: 14/08/2018
      # * Reviewed By:
      #
      # returns [Hash] api response data
      #
      def success_response_data
        {
            entity_type_and_data_hash: @entity_type_and_data_hash
        }
      end

    end

  end

end
