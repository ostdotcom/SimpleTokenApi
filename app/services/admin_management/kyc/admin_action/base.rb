module AdminManagement

  module Kyc

    module AdminAction

      class Base < ServicesBase

        # Initialize
        #
        # * Author: Alpesh
        # * Date: 15/10/2017
        # * Reviewed By:
        #
        # @param [Integer] admin_id (mandatory) - logged in admin
        # @param [Integer] case_id (mandatory)
        #
        # @return [AdminManagement::Kyc::CheckDetails]
        #
        def initialize(params)
          super

          @admin_id = @params[:admin_id]
          @case_id = @params[:case_id]
          @api_response_data = {}
          @user_kyc_detail = nil
        end

        # Perform
        #
        # * Author: Alpesh
        # * Date: 15/10/2017
        # * Reviewed By:
        #
        def perform

        end

        private

        # Validate & sanitize
        #
        # * Author: Alpesh
        # * Date: 15/10/2017
        # * Reviewed By:
        #
        # return [Result::Base]
        #
        def validate_and_sanitize
          r = validate
          return r unless r.success?

          @user_kyc_detail = UserKycDetail.where(id: @case_id).first

          return error_with_data(
              'am_k_aa_dk_1',
              'Closed case can not be changed.',
              'Closed case can not be changed.',
              GlobalConstant::ErrorAction.default,
              {}
          ) if @user_kyc_detail.case_closed?

          @user = User.where(id: @user_kyc_detail.user_id).first

          success
        end

        # log admin action
        #
        # * Author: Alpesh
        # * Date: 15/10/2017
        # * Reviewed By:
        #
        def log_admin_action
          BgJob.enqueue(
              UserActivityLogJob,
              {
                  user_id: @user_kyc_detail.user_id,
                  admin_id: @admin_id,
                  action: logging_action_type,
                  action_timestamp: Time.now.to_i
              }
          )
        end

      end

    end

  end

end
