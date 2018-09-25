module AdminManagement
  class Logout < ServicesBase

    # Initialize
    #
    # * Author: Aniket
    # * Date: 21/09/2018
    # * Reviewed By:
    #
    # @param [String] cookie_value (mandatory) -  admin cookie
    # @param [String] browser_user_agent (mandatory) - browser user agent
    #
    # @return [AdminManagement::Logout]
    #
    def initialize(params)
      super

      @cookie_value = params[:cookie_value]
      @browser_user_agent = params[:browser_user_agent]
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

      r = logout_admin
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
      r = AdminManagement::VerifyCookie::DoubleAuth.new(
          cookie_value: @cookie_value,
          browser_user_agent: @browser_user_agent,
          is_super_admin_role: false
      ).perform

      return r unless r.success?

      @admin_id = r.data[:admin_id]

      success
    end

    # Logout admin
    #
    # * Author: Aniket
    # * Date: 21/09/2018
    # * Reviewed By:
    #
    def logout_admin

      r = fetch_and_validate_admin
      return r unless r.success?

      @admin.last_otp_at = Time.now.to_i
      @admin.save!

      success
    end

  end
end
