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
          @admin_id = params[:admin_id]
        end

        # Perform
        #
        # * Author: Mayur
        # * Date: 15/01/2019
        # * Reviewed By:
        #
        # @return [Result::Base]
        #
        def perform

          r = validate
          return r unless r.success?

          r = fetch_and_validate_admin
          return r unless r.success?

          entry_in_logs_table

          admin_term_of_use_update

          success
        end

        def entry_in_logs_table
          TermsAcceptedLog.create!( admin_id: @admin_id,
                                    terms_version: GlobalConstant::Admin.get_latest_terms_version.keys[0]
          )
        end

        def admin_term_of_use_update

          @admin.terms_of_use = GlobalConstant::Admin.accepted_terms_of_use
          @admin.save!
        end



      end

    end
  end

end