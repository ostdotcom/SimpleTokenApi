module AdminManagement

  module Login

    module TermsOfUse

      class UpdateTermsOfUse < ServicesBase

        # Initialize
        #
        # * Author: Mayur
        # * Date: 15/01/2018
        # * Reviewed By:
        #
        # @params [String] admin_id (mandatory) - admin id
        #
        # @return [AdminManagement::Login::TermsOfUse::UpdateTermsOfUse]
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

          return success if has_accepted_terms_of_use?

          entry_in_logs_table

          admin_term_of_use_update

          success
        end

        def entry_in_logs_table
          TermsAcceptedLog.create!( admin_id: @admin_id,
                                    terms_version: GlobalConstant::Admin.admin_terms_of_use_array.keys[-1]
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