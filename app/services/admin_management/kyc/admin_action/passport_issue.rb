module AdminManagement

  module Kyc

    module AdminAction

      class PassportIssue < AdminManagement::Kyc::AdminAction::Base

        # Deny KYC by admin
        #
        # * Author: Alpesh
        # * Date: 15/10/2017
        # * Reviewed By:
        #
        # @param [Integer] admin_id (mandatory) - logged in admin
        #
        def initialize(params)
          super

          @admin_id = @params[:admin_id]
          @api_response_data = {}
        end

        # Deny KYC by admin
        #
        # * Author: Alpesh
        # * Date: 15/10/2017
        # * Reviewed By:
        #
        # return [Result::Base]
        #
        def perform
          success_with_data(@api_response_data)
        end

      end

    end

  end

end
