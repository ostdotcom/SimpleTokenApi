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

          r = validate_terms_of_use
          return r unless r.success?

          success_with_data(GlobalConstant::Admin.latest_admin_terms_of_use)
        end

        private

        # Validate if terms of use is already accepted by admin
        #
        # * Author: Tejas
        # * Date: 15/01/2018
        # * Reviewed By:
        #
        # @return [Result::Base]
        #
        def validate_terms_of_use
          if @admin.has_accepted_terms_of_use?
            err = error_with_internal_code('am_l_tou_g_vtou_1',
                                           'Terms of use is accepted',
                                           GlobalConstant::ErrorCode.temporary_redirect,
                                           {},
                                           {},
                                           {}
            )
            err.set_error_extra_info({redirect_url: GlobalConstant::WebUrls.admin_dashboard})
            return err
          end
        end

      end

    end

  end
end

