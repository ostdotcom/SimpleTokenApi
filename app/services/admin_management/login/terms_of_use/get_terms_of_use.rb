module AdminManagement

  module Login

    module TermsOfUse

      class GetTermsOfUse < ServicesBase

        # Initialize
        #
        # * Author: Tejas
        # * Date: 15/01/2018
        # * Reviewed By:
        #
        # @params [String] admin_id (mandatory) - admin id
        #
        # @return [AdminManagement::Login::TermsOfUse::GetTermsOfUse]
        #
        def initialize(params)
          super
          @admin_id = params[:admin_id]
        end

        # Perform
        #
        # * Author: Tejas
        # * Date: 15/01/2018
        # * Reviewed By:
        #
        # @return [Result::Base]
        #
        def perform

          r = validate
          return r unless r.success?

          r = fetch_and_validate_admin
          return r unless r.success?

          success_with_data(GlobalConstant::Admin.latest_admin_terms_of_use)

        end

      end

    end

  end
end

