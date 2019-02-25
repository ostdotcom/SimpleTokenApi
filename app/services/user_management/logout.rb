module UserManagement
  class Logout < ServicesBase

    # Initialize
    #
    # * Author: Aniket
    # * Date: 21/09/2018
    # * Reviewed By:
    #
    # @param [String] cookie_value (mandatory) -  admin cookie
    # @param [String] browser_user_agent (mandatory) - browser user agent
    # @param [String] domain (mandatory) - domain
    #
    # Sets user_id, client_id
    #
    # @return [AdminManagement::Logout]
    #
    def initialize(params)
      super

      @cookie_value = @params[:cookie_value]
      @browser_user_agent = @params[:browser_user_agent]
      @domain = @params[:domain]

      @user_id = nil
      @client = nil
    end

    # Perform
    #
    # * Author: Aniket
    # * Date: 21/09/2018
    # * Reviewed By:
    #
    def perform
      r = authenticate_request
      return r unless r.success?

      r = logout_user
      return r unless r.success?

      success
    end

    private

    # Authenticate admin cookie
    #
    # * Author: Aniket
    # * Date: 21/09/2018
    # * Reviewed By:
    #
    def authenticate_request
      r = UserManagement::VerifyClientHost.new(domain: @domain).perform
      return r unless r.success?

      @client = r.data[:client]

      r = UserManagement::VerifyCookie.new(
          client: @client,
          cookie_value: @cookie_value,
          browser_user_agent: @browser_user_agent
      ).perform
      return r unless r.success?

      @user_id = r.data[:user_id]

      success
    end

    # Logout user
    #
    # * Author: Aniket
    # * Date: 21/09/2018
    # * Reviewed By:
    #
    def logout_user
      @user = User.using_client_shard(client: @client).get_from_memcache(@user_id)
      return error_with_data('s_um_l_lu_1',
                             'Invalid user',
                             'Invalid user',
                             GlobalConstant::ErrorAction.default,
                             {}
      ) unless (@user.present? && @user.status == GlobalConstant::User.active_status)

      @user.last_logged_in_at = Time.now.to_i
      @user.save!

      success
    end

  end
end
