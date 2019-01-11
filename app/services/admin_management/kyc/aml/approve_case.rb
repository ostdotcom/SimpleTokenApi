module AdminManagement
module Kyc
  module Aml
    class ApproveCase < Base


      # Initialize
      #
      # * Author: mayur
      # * Date: 10/01/2019
      # * Reviewed By:
      # @params [Hash]
      # @return [AdminManagement::Kyc::Aml::ApproveCase]
      #
      def initialize(params)
        super

        @matched_ids = params[:matched_ids] || []
        @unmatched_ids = params[:unmatched_ids] || []

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

        update_user_kyc_status

        update_aml_match_status

        send_approved_email


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

        r = validate_aml_process_state
        return r unless r.success?

        r = validate_duplicacy_check
        return r unless r.success?

        r = validate_matches
        return r unless r.success?

        success
      end

      # update user kyc status
      #
      # * Author: mayur
      # * Date: 10/01/2019
      # * Reviewed By:
      #
      #
      def update_user_kyc_status
        @user_kyc_detail.admin_status = GlobalConstant::UserKycDetail.qualified_admin_status
        @user_kyc_detail.aml_status = GlobalConstant::UserKycDetail.approved_aml_status
        @user_kyc_detail.last_acted_by = @admin_id
        @user_kyc_detail.last_acted_timestamp = Time.now.to_i
        @user_kyc_detail.admin_action_types = 0

        # NOTE: we don't want to change the updated_at at this action. Don't touch before asking Sunil
        if @user_kyc_detail.changed?
          @user_kyc_detail.save!(touch: false)
          enqueue_job(get_event_source)
        end
      end

      # check if aml is processed or not
      #
      # * Author: mayur
      # * Date: 10/01/2019
      # * Reviewed By:
      #
      # @return [Result::Base]
      #
      def validate_aml_process_state
        return error_with_data(
            'ka_ad_vaps_1',
            'Aml is not processed for user',
            'Aml is not processed for user',
            GlobalConstant::ErrorAction.default,
            {}
        ) if aml_search.blank? || aml_search.status != GlobalConstant::AmlSearch.processed_status
        success
      end

      # validate duplicacy check if admin status is unprocessed
      #
      # * Author: mayur
      # * Date: 10/01/2019
      # * Reviewed By:
      #
      # @return [Result::Base]
      #

      def validate_duplicacy_check
        if @user_kyc_detail.admin_status == GlobalConstant::UserKycDetail.unprocessed_admin_status
          return validate_for_duplicate_user
        end
        success
      end

      # validate matched_ids and unmatched_ids
      #
      # * Author: mayur
      # * Date: 10/01/2019
      # * Reviewed By:
      #
      # @return [Result::Base]
      #
      def validate_matches

        return success if is_aml_auto_approved?

        # common ids in matches_ids and unmatched_ids
       r = validate_matched_unmatched_records
       return r unless r.success?


       r = validate_unmatched_ids
       return r unless r.success?

       success

      end


      # validate unmatched_ids, i.e unmatched_ids should have all aml match records if matched_ids are abesnt
      #
      # * Author: mayur
      # * Date: 10/01/2019
      # * Reviewed By:
      #
      # @return [Result::Base]
      #
      def validate_unmatched_ids

        return success if @matched_ids.present?
        aml_matches_qr_codes = aml_matches.map(&:qr_code)
        return error_with_data(
            'ka_ad_vmi_1',
            'Select all records as unmatched or select at least one as matched',
            'Select all records as unmatched or select at least one as matched',
            GlobalConstant::ErrorAction.default,
            {}
        ) unless (aml_matches_qr_codes - @unmatched_ids).blank? && (@unmatched_ids - aml_matches_qr_codes).blank?  # this condition check if aml_matches_qr_codes and unmatched_ids are same

        success
      end

    end
  end
end
end