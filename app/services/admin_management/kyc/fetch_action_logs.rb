module AdminManagement

  module Kyc

    class FetchActionLogs < ServicesBase

      # Initialize
      #
      # * Author: Alpesh
      # * Date: 21/10/2017
      # * Reviewed By: Sunil
      #
      # @params [Integer] admin_id (mandatory) - logged in admin
      # @params [Integer] case_id (mandatory) - user kyc details id
      # @params [Integer] limit (optional) - page size
      # @params [Integer] offset (optional) - offset
      #
      # @return [AdminManagement::Kyc::FetchActionLogs]
      #
      def initialize(params)
        super

        @admin_id = @params[:admin_id]
        @case_id = @params[:case_id]
        @limit = @params[:limit]
        @offset = @params[:offset]

        @user_kyc_detail = nil
        @logs_ars = nil
        @admin_details = nil
        @api_response = {
            curr_page_data: []
        }
      end

      # Perform
      #
      # * Author: Alpesh
      # * Date: 21/10/2017
      # * Reviewed By: Sunil
      #
      # @return [Result::Base]
      #
      def perform

        r = validate_and_sanitize
        return r unless r.success?

        fetch_records

        api_response
      end

      private

      # validate and sanitize
      #
      # * Author: Alpesh
      # * Date: 21/10/2017
      # * Reviewed By: Sunil
      #
      # @return [Result::Base]
      #
      def validate_and_sanitize
        r = validate
        return r unless r.success?

        @user_kyc_detail = UserKycDetail.where(id: @case_id).first
        return error_with_data(
            'am_k_fal_1',
            'KYC detail id not found',
            '',
            GlobalConstant::ErrorAction.default,
            {}
        ) if @user_kyc_detail.blank?


        @limit = 50 if @limit.to_i <= 0
        @offset = 0 if @offset.to_i <= 0

        success
      end

      # Fetch related entities
      #
      # * Author: Alpesh
      # * Date: 21/10/2017
      # * Reviewed By: Sunil
      #
      # Sets @logs_ars, @admin_details
      #
      def fetch_records
        @logs_ars = UserActivityLog.where(
            user_id: @user_kyc_detail.user_id,
            log_type: GlobalConstant::UserActivityLog.admin_log_type
        ).limit(@limit).offset(@offset).order('id DESC').all
        return if @logs_ars.blank?
        admin_ids = @logs_ars.collect(&:admin_id).compact.uniq
        return if admin_ids.blank?
        @admin_details = Admin.where(id: admin_ids).index_by(&:id)
      end

      # Format and send response.
      #
      # * Author: Alpesh
      # * Date: 21/10/2017
      # * Reviewed By: Sunil
      #
      # @return [Result::Base]
      #
      def api_response
        @logs_ars.each do |l_ar|
          data_hash = l_ar.e_data.present? ? LocalCipher.new(activity_log_decyption_salt).decrypt(l_ar.e_data).data[:plaintext] : {}

          admin_detail = (@admin_details.present? && l_ar.admin_id.present?) ? @admin_details[l_ar.admin_id] : {}
          activity_data = GlobalConstant::UserActivityLog.humanized_actions[l_ar.action] || l_ar.action
          activity_data += " ( #{data_hash[:error_fields].join(', ')} ) " if data_hash[:error_fields].present?
          @api_response[:curr_page_data] << {
              date_time: Time.at(l_ar.action_timestamp).strftime("%d/%m/%Y %H:%M"),
              agent: admin_detail['name'].to_s,
              activity: activity_data
          }
        end

        success_with_data(@api_response)
      end

      # Decrypted user activity salt
      #
      # * Author: Aman
      # * Date: 02/11/2017
      # * Reviewed By: Sunil
      #
      # @return [String] salt for user activity
      #
      def activity_log_decyption_salt
        @activity_log_decyption_salt ||= begin
          kms_login_client = Aws::Kms.new('entity_association', 'general_access')
          r = kms_login_client.decrypt(GeneralSalt.get_user_activity_logging_salt_type)
          r.data[:plaintext]
        end
      end

    end

  end

end
