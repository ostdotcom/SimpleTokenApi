module AdminManagement
  module Kyc
    module AdminAction
      class ApproveDetails < Base

        # Initialize
        #
        # * Author: mayur
        # * Date: 10/01/2019
        # * Reviewed By:
        #
        # @params [Integer] admin_id (mandatory) - logged in admin
        # @params [Integer] client_id (mandatory) - logged in admin's client id
        # @params [Integer] id (mandatory)
        #
        # @params [Boolean] is_auto_approve (Optional) - if its an auto approve qualify
        #
        # @return [AdminManagement::Kyc::AdminAction::ApproveDetails]
        #
        def initialize(params)
          super

          @is_auto_approve = params[:is_auto_approve]
        end

        # perform
        #
        # * Author: mayur
        # * Date: 10/01/2019
        # * Reviewed By:
        #
        # @return [Result::Base]
        #
        def perform
          r = validate_and_sanitize
          return r unless r.success?

          create_aml_search_record

          update_user_kyc_status

          send_approved_email

          fetch_case_details
        end

        private

        # validate and sanitize
        #
        # * Author: mayur
        # * Date: 10/01/2019
        # * Reviewed By:
        #
        # @return [Result::Base]
        #
        def validate_and_sanitize
          r = super
          return r unless r.success?

          r = validate_for_duplicate_user
          return r unless r.success?

          r = is_admin_status_pending?
          return r unless r.success?

          r = validate_if_case_closed_for_auto_approve_admin_action?
          return r unless r.success?

          success
        end

        # check aml search entry for case, if not present make entry, if aml approve make aml_status approve
        #
        # * Author: mayur
        # * Date: 10/01/2019
        # * Reviewed By:
        #
        #
        def create_aml_search_record
          AmlSearch.create!(user_kyc_detail_id: @user_kyc_detail.id,
                            user_extended_detail_id: @user_kyc_detail.user_extended_detail_id,
                            uuid: @user_kyc_detail.get_aml_search_uuid,
                            status: GlobalConstant::AmlSearch.unprocessed_status,
                            steps_done: 0,
                            retry_count: 0,
                            lock_id: nil) if @user_kyc_detail.is_aml_status_open? && aml_search.blank?
        end

        # update user kyc status
        #
        # * Author: mayur
        # * Date: 10/01/2019
        # * Reviewed By:
        #
        #
        def update_user_kyc_status
          if is_auto_approve_admin?
            @user_kyc_detail.send("set_" + GlobalConstant::UserKycDetail.auto_approved_qualify_type)
          else
            @user_kyc_detail.send("set_" + GlobalConstant::UserKycDetail.manually_approved_qualify_type)
          end

          @user_kyc_detail.admin_status = GlobalConstant::UserKycDetail.qualified_admin_status
          @user_kyc_detail.last_acted_by = @admin_id
          @user_kyc_detail.last_acted_timestamp = Time.now.to_i
          @user_kyc_detail.admin_action_types = 0

          # NOTE: we don't want to change the updated_at at this action. Don't touch before asking Sunil
          if @user_kyc_detail.changed?
            @user_kyc_detail.save!(touch: false)
            enqueue_job
          end

        end

        # fetch admin and validate. -1 Admin Id is for auto approve. dummy admin obj is initialized
        #
        # * Author: Aman
        # * Date: 10/07/2018
        # * Reviewed By:
        #
        # Sets @admin
        #
        # @return [Result::Base]
        #
        def fetch_and_validate_admin
          if is_auto_approve_admin?
            # this ar obj is used to enqueue event job as well
            @admin = Admin.new(id: @admin_id)
            success
          else
            super
          end
        end

        # check if admin status pending
        #
        # * Author: mayur
        # * Date: 10/01/2019
        # * Reviewed By:
        #
        # @return [Result::Base]
        #
        def is_admin_status_pending?
          if @user_kyc_detail.admin_status != GlobalConstant::UserKycDetail.unprocessed_admin_status
            return error_with_data(
                'ka_ad_iasp_1',
                'User details are already approved',
                'User details are already approved',
                GlobalConstant::ErrorAction.default,
                {}
            )
          end
          success
        end

        # validation if admin_status approved automatically
        #
        # * Author: mayur
        # * Date: 10/01/2019
        # * Reviewed By:
        #
        # @return [Result::Base]
        #
        def validate_if_case_closed_for_auto_approve_admin_action?
          return success if !is_auto_approve_admin?

          return error_with_data(
              'ka_ad_viccfaaaa_1',
              'Case has already been auto approved',
              'Case has already been auto approved',
              GlobalConstant::ErrorAction.default,
              {}
          ) if @user_kyc_detail.has_been_auto_approved?

          return error_with_data(
              'ka_ad_viccfaaaa_2',
              'Case cannot be auto approved',
              'Case cannot be auto approved',
              GlobalConstant::ErrorAction.default,
              {}
          ) if @user_kyc_detail.case_closed_for_auto_approve?

          return success
        end

        # check if admin status is auto_approved
        #
        # * Author: Mayur
        # * Date: 11/1/19
        # * Reviewed By:
        #
        def is_auto_approve_admin?
          @is_auto_approve && (@admin_id == Admin::AUTO_APPROVE_ADMIN_ID)
        end

        # get event source
        #
        # * Author: Mayur
        # * Date: 11/1/19
        # * Reviewed By:
        #
        def event_source
          is_auto_approve_admin? ? GlobalConstant::Event.kyc_system_source : GlobalConstant::Event.web_source
        end

      end
    end
  end
end