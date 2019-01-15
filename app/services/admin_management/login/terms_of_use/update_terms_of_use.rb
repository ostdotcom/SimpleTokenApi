module AdminManagement

  module Login

    module TermsOfUse

      class UpdateTermsOfUse < ServicesBase

        # Initialize
        #
        # * Author: Aman
        # * Date: 10/10/2017
        # * Reviewed By: Sunil
        #
        # @params [String] single_auth_cookie_value (mandatory) - single auth cookie value
        # @params [String] otp (mandatory) - this is the Otp entered
        # @params [String] browser_user_agent (mandatory) - browser user agent
        #
        # @return [AdminManagement::Login::Multifactor::Authenticate]
        #
        def initialize(params)
          super

        end

        # Perform
        #
        # * Author: Aman
        # * Date: 10/10/2017
        # * Reviewed By: Sunil
        #
        # @return [Result::Base]
        #
        def perform

          r = validate
          return r unless r.success?



          success_with_data({})
        end



      end

    end
  end

end