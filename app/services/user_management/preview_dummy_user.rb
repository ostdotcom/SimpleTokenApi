module UserManagement

  class PreviewDummyUser < GetClientDetail

    # Initialize
    #
    # * Author: Pankaj
    # * Date: 16/08/2018
    # * Reviewed By:
    #
    # @param [Integer] client_id (mandatory) - client id
    # @params [String] template_type (mandatory) - this is the page template name
    # @params [boolean] in_preview_mode (mandatory) - this is to open urls in preview mode
    # @params [Integer] gid (mandatory) - this is to open urls in preview mode for some group id
    #
    # @return [UserManagement::PreviewDummyUser]
    #
    def initialize(params)
      super

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

    def fetch_user
      @user = User.new
      @user.id = Random.rand(100..1000)
      @user.properties = User.properties_config[GlobalConstant::User.token_sale_kyc_submitted_property]
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
          sale_end_timestamp: (Time.now + 1.month).to_i
      )
    end

  end

end