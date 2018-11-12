module AdminManagement

  module CmsConfigurator

    class GetPublishedDraft < ServicesBase

      # Initialize
      #
      # * Author: Tejas
      # * Date: 08/08/2018
      # * Reviewed By:
      #
      # @params [Hash] decoded_token_data (mandatory) - it contains uuid of the client
      #
      # @return [AdminManagement::CmsConfigurator::GetPublishedDraft]
      #
      def initialize(params)
        super
        @decoded_token_data = @params[:decoded_token_data]
        @uuid = @decoded_token_data[:uuid]

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

        return error_with_identifier("no_configurator_access", "am_cc_gpd_v_1") if !@client.is_web_host_setup_done?

        success
      end

      # fetch client and validate
      #
      # * Author: Aman
      # * Date: 26/12/2017
      # * Reviewed By:
      #
      # Sets @client
      #
      # @return [Result::Base]
      #
      def fetch_and_validate_client
        @uuid = "sandbox_#{@uuid}"
        @client = Client.where(uuid: @uuid).first

        return error_with_identifier("invalid_client_id", "am_cc_gpd_favc_1") if @client.blank? ||
            @client.status != GlobalConstant::Client.active_status

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
        entity_draft_hash_for_gid = PublishedEntityGroup.fetch_published_draft_ids(@client.id)

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
