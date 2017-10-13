module UserManagement

  class GetBasicDetail < ServicesBase

    # Initialize
    #
    # * Author: Aman
    # * Date: 12/10/2017
    # * Reviewed By: Sunil
    #
    # @param [Integer] user_id (mandatory) - this is the user id
    # @param [String] user_token_sale_state (optional) - this is the user state
    #
    # @return [UserManagement::GetBasicDetail]
    #
    def initialize(params)
      super

      @user_id = @params[:user_id]
      @user_token_sale_state = @params[:user_token_sale_state]

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

      fetch_user

      success_with_data(user: user_data)
    end

    private

    # Fetch User
    #
    # * Author: Aman
    # * Date: 12/10/2017
    # * Reviewed By: Sunil
    #
    # Sets @user
    #
    def fetch_user
      @user = User.where(id: @user_id).first
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
          token_sale_state: @user_token_sale_state
      }
    end

  end

end