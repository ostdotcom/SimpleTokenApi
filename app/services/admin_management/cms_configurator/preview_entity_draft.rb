module AdminManagement

  module CmsConfigurator

    class PreviewEntityDraft < UserManagement::GetClientDetail

      # Initialize
      #
      # * Author: Pankaj
      # * Date: 16/08/2018
      # * Reviewed By:
      #
      # @param [AR] client (mandatory) - client obj
      # @params [String] template_type (mandatory) - this is the page template name
      # @params [Integer] gid (mandatory) - this is to open urls in preview mode for some group id
      #
      # @return [AdminManagement::CmsConfigurator::PreviewEntityDraft]
      #
      def initialize(params)
        super

        @entity_group_id = @params[:gid]

        @user = nil
        @user_token_sale_state = nil
      end

      # Perform
      #
      # * Author: Pankaj
      # * Date: 16/08/2018
      # * Reviewed By:
      #
      # @return [Result::Base]
      #
      def perform
        r = super
        return r unless r.success?

        @client_setting = r.data

        set_live_sale_for_client

        fetch_user

        success_with_data(api_response)
      end

      private

      # validate and sanitize params data
      #
      # * Author: Aman
      # * Date: 01/02/2018
      # * Reviewed By:
      #
      # @return [Result::Base]
      #
      def validate_and_sanitize
        r = super
        return r unless r.success?

        eg = EntityGroup.get_entity_group_from_memcache(@entity_group_id)
        return error_with_data(
            'um_gcd_2',
            'Invalid Entity Group in Preview mode',
            'Invalid Entity Group in Preview mode',
            GlobalConstant::ErrorAction.default,
            {}
        ) if eg.blank? || (eg.client_id != @client_id)

        success
      end

      def fetch_user
        @user = User.using_shard(shard_identifier: @client.sql_shard_identifier).new
        @user.id = Random.rand(100..1000)
        @user.properties = User.properties_config[GlobalConstant::User.kyc_submitted_property]
        @user_token_sale_state = @user.get_token_sale_state_page_name
      end

      def api_response
        {
          user: user_data,
          user_kyc_data: user_kyc_data
        }.merge!(@client_setting)
      end

      def user_data
        {
          id: @user.id,
          email: "user@email.com",
          user_token_sale_state: @user_token_sale_state
        }
      end

      def user_kyc_data
        {
          user_id: @user.id,
          kyc_status: GlobalConstant::UserKycDetail.kyc_approved_status,
          admin_action_types: [],
          token_sale_participation_phase: GlobalConstant::TokenSale.early_access_token_sale_phase,
          whitelist_status: GlobalConstant::UserKycDetail.done_whitelist_status
        }
      end

      # Set client sale as live always
      #
      # * Author: Pankaj
      # * Date: 16/08/2018
      # * Reviewed By:
      #
      # Sets @client_setting
      #
      def set_live_sale_for_client
        @client_setting[:client_setting][:token_sale_details].merge!(
            sale_start_timestamp: Time.now.to_i,
            registration_end_timestamp: (Time.now + 1.month).to_i,
            sale_end_timestamp: (Time.now + 1.month).to_i
        )
      end

      # Allowed entity types to open saas user pages
      #
      # * Author: Pankaj
      # * Date: 16/08/2018
      # * Reviewed By:
      #
      # @return [Array] - Allowed entity types
      #
      def allowed_entity_types
        [
            GlobalConstant::EntityGroupDraft.theme_entity_type,
            GlobalConstant::EntityGroupDraft.registration_entity_type,
            GlobalConstant::EntityGroupDraft.kyc_entity_type,
            GlobalConstant::EntityGroupDraft.dashboard_entity_type
        ]
      end

    end

  end

end