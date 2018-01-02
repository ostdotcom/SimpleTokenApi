module AdminManagement

  module Kyc

    module AdminAction

      class Base < ServicesBase

        # Initialize
        #
        # * Author: Alpesh
        # * Date: 15/10/2017
        # * Reviewed By: Sunil
        #
        # @params [Integer] admin_id (mandatory) - logged in admin
        # @params [Integer] client_id (mandatory) - logged in admin's client id
        # @params [Integer] case_id (mandatory)
        #
        # @return [AdminManagement::Kyc::AdminAction::Base]
        #
        def initialize(params)
          super

          @admin_id = @params[:admin_id]
          @client_id = @params[:client_id]
          @case_id = @params[:case_id]

          @email_temp_vars = @params[:email_temp_vars] || {}

          @api_response_data = {}
          @user_kyc_detail = nil
          @extra_data = nil
        end

        private

        # Validate & sanitize
        #
        # * Author: Alpesh
        # * Date: 15/10/2017
        # * Reviewed By: Sunil
        #
        # return [Result::Base]
        #
        def validate_and_sanitize
          r = validate
          return r unless r.success?

          r = fetch_and_validate_client
          return r unless r.success?

          @user_kyc_detail = UserKycDetail.where(client_id: @client_id, id: @case_id).first

          return error_with_data(
              'am_k_aa_dk_1',
              'Closed case can not be changed.',
              'Closed case can not be changed.',
              GlobalConstant::ErrorAction.default,
              {}
          ) if @user_kyc_detail.case_closed?

          @user = User.where(client_id: @client_id, id: @user_kyc_detail.user_id).first

          success
        end

        # fetch client and validate
        #
        # * Author: Aman
        # * Date: 26/12/2017
        # * Reviewed By:
        #
        # Sets @client
        #
        # @return [Result::Base]
        #
        def fetch_and_validate_client
          @client = Client.get_from_memcache(@client_id)

          return error_with_data(
              'am_k_ac_b_2',
              'Client is not active',
              'Client is not active',
              GlobalConstant::ErrorAction.default,
              {}
          ) if @client.status != GlobalConstant::Client.active_status

          success
        end

        # check if client has Email setup
        #
        # * Author: Aman
        # * Date: 26/12/2017
        # * Reviewed By:
        #
        # @return [Result::Base]
        #
        def validate_for_email_setup

          return error_with_data(
              'am_k_ac_b_3',
              'Client has not completed email setup',
              'Client has not completed email setup',
              GlobalConstant::ErrorAction.default,
              {}
          ) unless @client.is_email_setup_done?

          success
        end

        # log admin action
        #
        # * Author: Alpesh
        # * Date: 15/10/2017
        # * Reviewed By: Sunil
        #
        def log_admin_action
          BgJob.enqueue(
              UserActivityLogJob,
              {
                  user_id: @user_kyc_detail.user_id,
                  case_id: @case_id,
                  admin_id: @admin_id,
                  action: logging_action_type,
                  action_timestamp: Time.now.to_i,
                  extra_data: @extra_data
              }
          )
        end

      end

    end

  end

end
