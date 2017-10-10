module AdminManagement

  class VerifyCookie < ServicesBase

    # Initialize
    #
    # * Author: Kedar
    # * Date: 10/10/2017
    # * Reviewed By: Sunil Khedar
    #
    # @param [String] cookie_value (mandatory) - this is the admin cookie value
    #
    # @return [AdminManagement::VerifyCookie]
    #
    def initialize(params)
      super

      @cookie_value = @params[:cookie_value]
      @action = @params[:action]
      @controller = @params[:controller]
    end

    # Perform
    #
    # * Author: Kedar
    # * Date: 10/10/2017
    # * Reviewed By: Sunil Khedar
    #
    # @return [AdminManagement::VerifyCookie]
    #
    def perform
      return success
      r = validate
      return r unless r.success?

      r = fetch_cookie_type
      return r unless r.success?

      r = set_parts_using_cookie_type
      return r unless r.success?

      r = validate_cookie_parts
      return r unless r.success?

      r = validate_controller_action
      return r unless r.success?

      rotate_cookie_if_needed

    end

    private

    def fetch_cookie_type
      success
    end

    def set_parts_using_cookie_type
      success
    end

    def validate_cookie_parts
      success
    end

    def validate_controller_action
      success
    end

  end

end