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
      # @params [Integer] client_id (mandatory) - logged in admin's client id
      # @params [Integer] id (mandatory) - user kyc details id
      # @params [Integer] page_number (optional) - page number if present
      # @params [Integer] page_size (optional) - page size if present
      #
      # @return [AdminManagement::Kyc::FetchActionLogs]
      #
      def initialize(params)
        super

        @admin_id = @params[:admin_id]
        @client_id = @params[:client_id]
        @case_id = @params[:id]
        @page_number = @params[:page_number].to_i
        @page_size = @params[:page_size].to_i

        @user_kyc_detail = nil
        @logs_ars = nil
        @admin_details = nil

        @curr_page_data = []
        @api_response_data = {}
        @total_action_logs = 0
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

        set_api_response_data

        success_with_data(@api_response_data)
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

        @user_kyc_detail = UserKycDetail.where(client_id: @client_id, id: @case_id).first
        return error_with_data(
            'am_k_fal_1',
            'KYC detail id not found',
            '',
            GlobalConstant::ErrorAction.default,
            {}
        ) if @user_kyc_detail.blank?

        r = fetch_and_validate_client
        return r unless r.success?

        r = fetch_and_validate_admin
        return r unless r.success?

        @page_number = 1 if @page_number < 1
        @page_size = 50 if @page_size == 0 || @page_size > 50

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
        offset = 0
        offset = @page_size * (@page_number - 1) if @page_number > 1

        ar_relation = UserActivityLog.where(
            user_id: @user_kyc_detail.user_id,
            log_type: GlobalConstant::UserActivityLog.admin_log_type
        )

        @total_action_logs = ar_relation.count

        @logs_ars = ar_relation.limit(@page_size).offset(offset).order('id DESC').all
        return if @logs_ars.blank?

        admin_ids = @logs_ars.collect(&:admin_id).compact.uniq
        return if admin_ids.blank?

        @admin_details = Admin.where(id: admin_ids).index_by(&:id)
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

      # Set API response data
      #
      # * Author: Alpesh
      # * Date: 24/10/2017
      # * Reviewed By: sunil
      #
      # Sets @api_response_data
      #
      def set_api_response_data

        @logs_ars.each do |l_ar|
          data_hash = l_ar.e_data.present? ? LocalCipher.new(activity_log_decyption_salt).decrypt(l_ar.e_data).data[:plaintext] : {}
          admin_detail = (@admin_details.present? && l_ar.admin_id.present?) ? @admin_details[l_ar.admin_id] : {}
          activity_data = data_hash
          @curr_page_data << {
              created_at_timestamp: Util::DateTimeHelper.get_formatted_time(l_ar.action_timestamp),
              agent: admin_detail['name'].to_s,
              action: l_ar.action,
              action_data: activity_data
          }
        end

        meta = {
            page_number: @page_number,
            page_payload: {
            },
            page_size: @page_size,
            total_records: @total_action_logs,
        }

        data = {
            meta: meta,
            result_set: 'admin_logs',
            admin_logs: @curr_page_data
        }

        @api_response_data = data
      end

    end

  end

end
