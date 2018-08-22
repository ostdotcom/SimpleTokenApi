module AdminManagement

  module CmsConfigurator

    class Index < ServicesBase

      # Initialize
      #
      # * Author: Tejas
      # * Date: 08/08/2018
      # * Reviewed By:
      #
      # @params [Integer] client_id (mandatory) - logged in admin's client id
      # @params [Integer] admin_id (mandatory) - logged in admin's id
      #
      # @return [AdminManagement::CmsConfigurator::Index]
      #
      def initialize(params)
        super

        @client_id = @params[:client_id]
        @admin_id = @params[:admin_id]

        @entity_group = nil
        @gid = nil
        @uuid = nil
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

        r = fetch_entity_group_id
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

        r = fetch_and_validate_admin
        return r unless r.success?

        success
      end

      # Fetch Entity Group Id
      #
      # * Author: Tejas
      # * Date: 14/08/2018
      # * Reviewed By:
      #
      # Sets @entity_draft, @gid, @uuid
      #
      def fetch_entity_group_id

        @entity_group = EntityGroup.where(client_id: @client_id, creator_admin_id: @admin_id,
                                          status: GlobalConstant::EntityGroup.incomplete_status).last

        if !@entity_group.blank?
          @gid = @entity_group.id
          @uuid = @entity_group.uuid
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
            gid: @gid,
            uuid: @uuid
        }
      end

    end

  end

end
