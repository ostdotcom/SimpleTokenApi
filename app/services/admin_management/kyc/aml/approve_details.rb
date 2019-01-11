module AdminManagement
module Kyc
  module Aml
    class ApproveDetails < Base

      # Initialize
      #
      # * Author: mayur
      # * Date: 10/01/2019
      # * Reviewed By:
      # @params [Hash]
      # @return [AdminManagement::Kyc::Aml::ApproveDetails]
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

        check_aml_data

        update_user_kyc_status

        send_email

        success_with_data(@api_response_data)

      end

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

        # admin status should be pending?
        # validation for auto approve cron

        r =  validate_for_duplicate_user
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
      def check_aml_data
        if is_aml_status_open?
          if aml_search.present? # is aml search started ?
            @user_kyc_detail.aml_status = GlobalConstant::UserKycDetail.approved_aml_status if is_aml_auto_approved?
          else
            entry_in_aml_search_table
          end
        end
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
          enqueue_job(get_event_source)
        end

      end

      # check if aml status open
      #
      # * Author: mayur
      # * Date: 10/01/2019
      # * Reviewed By:
      #
      # @return [Boolean]
      #
      def is_aml_status_open?
         [GlobalConstant::UserKycDetail.unprocessed_aml_status,
          GlobalConstant::UserKycDetail.pending_aml_status].include?(@user_kyc_detail.aml_status)
      end

      # entry in aml search table
      #
      # * Author: mayur
      # * Date: 10/01/2019
      # * Reviewed By:
      #
      # @return [Boolean]
      #
      def entry_in_aml_search_table
        AmlSearch.create!(user_kyc_detail_id: @user_kyc_detail.id,
                          user_extended_detail_id: @user_kyc_detail.user_extended_detail_id,
                          uuid: aml_search_uuid,
                          status: GlobalConstant::AmlSearch.unprocessed_status,
                          steps_done: 0,
                          retry_count: 0)
      end

      # create aml search uuid
      #
      # * Author: mayur
      # * Date: 10/01/2019
      # * Reviewed By:
      #
      # @return [String]
      #
      def aml_search_uuid
        "#{Rails.env[0..1]}_#{@user_kyc_detail.id}_#{@user_kyc_detail.user_extended_detail_id}"
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
        ) if @user_kyc_detail.last_reopened_at.to_i > 0

        return success
      end

      # send approve email if aml is auto approved
      #
      # * Author: mayur
      # * Date: 10/01/2019
      # * Reviewed By:
      #
      #
      def send_email
        if is_aml_auto_approved?
          send_approved_email
        end
      end



    end
  end
end
end