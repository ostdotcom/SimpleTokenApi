module UserManagement

  class GetBasicDetail < ServicesBase

    # Initialize
    #
    # * Author: Aman
    # * Date: 12/10/2017
    # * Reviewed By: Sunil
    #
    # @param [Integer] client_id (mandatory) - client id
    # @params [Integer] user_id (mandatory) - this is the user id
    #
    # @return [UserManagement::GetBasicDetail]
    #
    def initialize(params)
      super

      @client_id = @params[:client_id]
      @user_id = @params[:user_id]

      @client = nil
      @user = nil
    end

    # Perform
    #
    # * Author: Aman
    # * Date: 12/10/2017
    # * Reviewed By: Sunil
    #
    # @return [Result::Base]
    #
    def perform
      r = validate
      return r unless r.success?

      r = fetch_and_validate_client
      return r unless r.success?

      r = validate_client_details
      return r unless r.success?

      fetch_user

      success_with_data(user: user_data)
    end

    private

    # validate clients web hosting setup details
    #
    # * Author: Aman
    # * Date: 01/02/2018
    # * Reviewed By:
    #
    # Sets @client
    #
    # @return [Result::Base]
    #
    def validate_client_details
      return error_with_data(
          'um_gbd_1',
          'Client is not active',
          'Client is not active',
          GlobalConstant::ErrorAction.default,
          {}
      ) if !@client.is_web_host_setup_done?

      success
    end

    # Fetch User
    #
    # * Author: Aman
    # * Date: 12/10/2017
    # * Reviewed By: Sunil
    #
    # Sets @user
    #
    def fetch_user
      @user = User.get_from_memcache(@user_id)
    end

    # User detail
    #
    # * Author: Aman
    # * Date: 12/10/2017
    # * Reviewed By: Sunil
    #
    # @return [Hash] hash of user data
    #
    def user_data
      {
          id: @user.id,
          email: @user.email,
          user_token_sale_state: @user.get_token_sale_state_page_name,
          bt_name: @user.bt_name.to_s,
          is_st_token_sale_client: @client.is_st_token_sale_client?
      }
    end

  end

end