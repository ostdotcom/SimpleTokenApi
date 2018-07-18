module AdminManagement

  module Kyc

    class CheckDetails < ServicesBase

      # Initialize
      #
      # * Author: Kedar
      # * Date: 14/10/2017
      # * Reviewed By: Sunil
      #
      # @params [Integer] admin_id (mandatory) - logged in admin
      # @params [Integer] client_id (mandatory) - logged in admin's client id
      # @params [Integer] id (mandatory)
      # @params [Hash] filters (optional) - Dashboard filter to go back on same dash page
      # @params [Hash] sortings (optional) - Dashboard sorting to go back on same dash page
      #
      # @return [AdminManagement::Kyc::CheckDetails]
      #
      def initialize(params)
        super

        @admin_id = @params[:admin_id]
        @client_id = @params[:client_id]
        @case_id = @params[:id]
        @filters = @params[:filters]
        @sortings = @params[:sortings]

        @user_kyc_detail = nil
        @user = nil
        @next_kyc_id, @previous_kyc_id = nil, nil

        @user_extended_detail = nil
        @kyc_salt_e = nil
        @user_geoip_data = {}
        @kyc_salt_d = nil
        @client_kyc_config_detail = nil

        @user_kyc_comparison_detail, @client_kyc_pass_setting = nil, nil

        @api_response_data = {}
      end

      # Perform
      #
      # * Author: Kedar
      # * Date: 14/10/2017
      # * Reviewed By: Sunil
      #
      # @return [Result::Base]
      #
      def perform
        r = validate_and_sanitize
        return r unless r.success?

        r = fetch_user_kyc_detail
        return r unless r.success?

        fetch_client_kyc_config

        fetch_surround_kyc_ids

        r = fetch_user_extended_detail
        return r unless r.success?

        r = decrypt_kyc_salt
        return r unless r.success?

        fetch_user_kyc_comparison_detail

        fetch_client_pass_setting

        set_api_response_data

        success_with_data(@api_response_data)
      end

      private

      # Validate and sanitize
      #
      # * Author: Aman
      # * Date: 26/04/2018
      # * Reviewed By:
      #
      def validate_and_sanitize
        r = validate
        return r unless r.success?

        @filters = {} if @filters.blank? || !(@filters.is_a?(Hash) || @filters.is_a?(ActionController::Parameters))
        @sortings = {} if @sortings.blank? || !(@sortings.is_a?(Hash) || @sortings.is_a?(ActionController::Parameters))


        sanitized_filter = @filters.dup

        if @filters.present?
          @filters.each do |key, val|
            if GlobalConstant::UserKycDetail.filters[key.to_s].blank?
              sanitized_filter.delete(key)
              next
            end

            filter_data = GlobalConstant::UserKycDetail.filters[key.to_s][val.to_s]
            sanitized_filter.delete(key) if filter_data.nil?
          end
        end

        sanitized_sorting = @sortings.dup

        if @sortings.present?
          @sortings.each do |key, val|

            if GlobalConstant::UserKycDetail.sorting[key.to_s].blank?
              sanitized_sorting.delete(key)
              next
            end

            sort_data = GlobalConstant::UserKycDetail.sorting[key.to_s][val.to_s]
            sanitized_sorting.delete(key) if sort_data.nil?
          end
        end

        @filters = sanitized_filter
        @sortings = sanitized_sorting

        r = fetch_and_validate_client
        return r unless r.success?

        r = fetch_and_validate_admin
        return r unless r.success?

        success
      end

      # Fetch user kyc detail
      #
      # * Author: Kedar
      # * Date: 14/10/2017
      # * Reviewed By: Sunil
      #
      # Sets @user, @user_kyc_detail
      #
      def fetch_user_kyc_detail
        @user_kyc_detail = UserKycDetail.where(client_id: @client_id, id: @case_id).first
        return err_response('am_k_cd_2') if @user_kyc_detail.blank? || @user_kyc_detail.inactive_status?

        @user = User.where(client_id: @client_id, id: @user_kyc_detail.user_id).first
        return err_response('am_k_cd_3') if @user.blank?

        success
      end

      # Fetch Client kyc config detail
      #
      # * Author: Aman
      # * Date: 09/05/2018
      # * Reviewed By:
      #
      # Sets @client_kyc_config_detail
      #
      def fetch_client_kyc_config
        @client_kyc_config_detail = ClientKycConfigDetail.get_from_memcache(@client_id)
      end

      # Fetch next and previous kyc ids
      #
      # * Author: Alpesh
      # * Date: 24/10/2017
      # * Reviewed By:
      #
      # Sets @next_kyc_id, @previous_kyc_id
      #
      def fetch_surround_kyc_ids
        return if @filters.blank? && @sortings.blank?

        ar_relation = UserKycDetail.where(client_id: @client_id).active_kyc
        ar_relation = ar_relation.filter_by(@filters)
        ar_relation = ar_relation.select(:id)

        if @sortings.present? && @sortings[:sort_order] == 'asc'
          kyc_1 = ar_relation.where("user_extended_detail_id > ?", @user_kyc_detail.user_extended_detail_id).first
          kyc_2 = ar_relation.where("user_extended_detail_id < ?", @user_kyc_detail.user_extended_detail_id).last
          @next_kyc_id = kyc_1.id if kyc_1.present?
          @previous_kyc_id = kyc_2.id if kyc_2.present?
        else
          kyc_1 = ar_relation.where("user_extended_detail_id < ?", @user_kyc_detail.user_extended_detail_id).last
          kyc_2 = ar_relation.where("user_extended_detail_id > ?", @user_kyc_detail.user_extended_detail_id).first
          @next_kyc_id = kyc_1.id if kyc_1.present?
          @previous_kyc_id = kyc_2.id if kyc_2.present?
        end
      end

      # Fetch user extended detail
      #
      # * Author: Kedar
      # * Date: 14/10/2017
      # * Reviewed By: Sunil
      #
      # Sets @user_extended_detail, @kyc_salt_e
      #
      def fetch_user_extended_detail
        @user_extended_detail = UserExtendedDetail.where(id: @user_kyc_detail.user_extended_detail_id).first
        return err_response('am_k_cd_4') if @user_extended_detail.blank?

        @kyc_salt_e = @user_extended_detail.kyc_salt

        user_registration_data = UserActivityLog.where(user_id: @user.id, action: GlobalConstant::UserActivityLog.register_action).first
        if user_registration_data.present? && user_registration_data.e_data.present?
          decrypted_data = user_registration_data.decrypted_extra_data
          @user_geoip_data[:country] = decrypted_data[:geoip_country]
          @user_geoip_data[:ip_address] = decrypted_data[:ip_address]
        end

        success
      end

      # Decrypt kyc salt
      #
      # * Author: Kedar, Puneet
      # * Date: 12/10/2017
      # * Reviewed By: Sunil
      #
      # Sets @kyc_salt_d
      #
      def decrypt_kyc_salt
        r = Aws::Kms.new('kyc', 'admin').decrypt(@kyc_salt_e)
        return err_response('am_k_cd_5') unless r.success?

        @kyc_salt_d = r.data[:plaintext]
        success
      end

      # Set API response data
      #
      # * Author: Kedar, Puneet
      # * Date: 12/10/2017
      # * Reviewed By: Sunil
      #
      # Sets @api_response_data
      #
      def set_api_response_data

        next_page_payload = @next_kyc_id.present? ? {
            id: @next_kyc_id,
            filters: @filters,
            sortings: @sortings,
        } : {}

        previous_page_payload = @previous_kyc_id.present? ? {
            id: @previous_kyc_id,
            filters: @filters,
            sortings: @sortings,
        } : {}

        meta = {
            filters: @filters,
            sortings: @sortings,
            id: @case_id,
            next_page_payload: next_page_payload,
            previous_page_payload: previous_page_payload
        }

        client_kyc_pass_setting = {
            approve_type: @client_kyc_pass_setting.approve_type,
            fr_match_percent: @client_kyc_pass_setting.face_match_percent.to_i,
            ocr_comparison_fields: @client_kyc_pass_setting.ocr_comparison_fields_array
        }

        auto_approve_failed_reasons = @user_kyc_comparison_detail.auto_approve_failed_reasons_array &
            GlobalConstant::KycAutoApproveFailedReason.auto_approve_fail_reasons

        user_kyc_comparison_detail = {
            image_processing_status: @user_kyc_comparison_detail.image_processing_status,
            failed_reason: auto_approve_failed_reasons,
            document_dimensions: @user_kyc_comparison_detail.document_dimensions,
            selfie_dimensions: @user_kyc_comparison_detail.selfie_dimensions,
            face_match_percent: [@user_kyc_comparison_detail.big_face_match_percent,
                                 @user_kyc_comparison_detail.small_face_match_percent].min
        }


        ai_pass_details = {}

        if @user_kyc_comparison_detail.image_processing_status == GlobalConstant::ImageProcessing.processed_image_process_status
          automation_passed = @user_kyc_detail.qualify_types_array.include?(GlobalConstant::UserKycDetail.auto_approved_qualify_type)
          ai_pass_details = {
              fr_pass_status: @user_kyc_comparison_detail.auto_approve_failed_reasons_array.exclude?(GlobalConstant::KycAutoApproveFailedReason.fr_unmatch),
              ocr_match_status: @user_kyc_comparison_detail.auto_approve_failed_reasons_array.exclude?(GlobalConstant::KycAutoApproveFailedReason.ocr_unmatch),
              automation_passed: automation_passed
          }

          ClientKycPassSetting.ocr_comparison_fields_config.keys do |key|
            ai_pass_details["#{key}_pass".to_sym] = @user_kyc_comparison_detail["#{key}_match_percent"].to_i == 100
          end

        end

        @api_response_data = {
            user_detail: user_detail,
            case_detail: case_detail,
            client_kyc_pass_setting: client_kyc_pass_setting,
            user_kyc_comparison_detail: user_kyc_comparison_detail,
            ai_pass_detail: ai_pass_details,
            meta: meta
        }
      end

      # User detail
      #
      # * Author: Kedar, Puneet
      # * Date: 12/10/2017
      # * Reviewed By: Sunil
      #
      # @return [Hash]
      #
      def user_detail
        u_detail = {
            first_name: @user_extended_detail.first_name,
            last_name: @user_extended_detail.last_name,
            birthdate: birthdate_d,
            street_address: street_address_d,
            city: city_d,
            state: state_d,
            country: country_d,
            postal_code: postal_code_d,
            document_id_number: document_id_number_d,
            nationality: nationality_d,

            document_id_file_url: document_id_file_url,
            selfie_file_url: selfie_file_url,
            residence_proof_file_url: residence_proof_file_url,
            investor_proof_files_url: investor_proof_files_urls,

            email: @user.email,
            submitted_at: Util::DateTimeHelper.get_formatted_time(@user_extended_detail.created_at.to_i),
            geoip_data: @user_geoip_data
        }

        fields_to_check = ["first_name", "last_name", "birthdate", "street_address", "city", "state", "country", "postal_code", "document_id_number", "nationality"]

        fields_to_check.each do |kyc_field|
          u_detail.delete(kyc_field.to_sym) if @client_kyc_config_detail.kyc_fields_array.exclude?(kyc_field)
        end

        u_detail.delete("investor_proof_files_url".to_sym) if @client_kyc_config_detail.kyc_fields_array.exclude?(GlobalConstant::ClientKycConfigDetail.investor_proof_files_path_kyc_field)

        u_detail
      end

      # Case detail
      #
      # * Author: Kedar, Puneet
      # * Date: 12/10/2017
      # * Reviewed By: Sunil
      #
      # @return [Hash]
      #
      def case_detail
        {
            admin_status: @user_kyc_detail.admin_status,
            last_qualified_type: @user_kyc_detail.last_qualified_type,
            cynopsis_status: @user_kyc_detail.cynopsis_status,
            retry_cynopsis: (@user_kyc_detail.cynopsis_status == GlobalConstant::UserKycDetail.failed_cynopsis_status).to_i,
            submission_count: @user_kyc_detail.submission_count.to_i,
            is_re_submitted: @user_kyc_detail.is_re_submitted?,
            is_duplicate: @user_kyc_detail.show_duplicate_status.to_i,
            last_acted_by: last_acted_by,
            whitelist_status: @user_kyc_detail.whitelist_status,
            last_issue_email_sent: @user_kyc_detail.admin_action_types_array,
            last_issue_email_sent_humanized: @user_kyc_detail.admin_action_types_array.map {|x| x.humanize},
            is_case_closed: @user_kyc_detail.case_closed_for_admin?.to_i,
            kyc_status: kyc_status,
            can_reopen_case: (@user_kyc_detail.case_closed_for_admin? && (@user_kyc_detail.cynopsis_status != GlobalConstant::UserKycDetail.rejected_cynopsis_status)).to_i,
            case_reopen_inprocess: is_case_reopening_under_process?,
            whitelist_confirmation_pending: whitelist_confirmation_pending.to_i
        }
      end

      # User Kyc Status
      #
      # * Author: Aman
      # * Date: 12/10/2017
      # * Reviewed By: Sunil
      #
      # @return [String] status of kyc
      #
      def kyc_status
        case true
          when @user_kyc_detail.kyc_approved?
            GlobalConstant::UserKycDetail.kyc_approved_status
          when @user_kyc_detail.kyc_denied?
            GlobalConstant::UserKycDetail.kyc_denied_status
          when @user_kyc_detail.kyc_pending?
            GlobalConstant::UserKycDetail.kyc_pending_status
          else
            fail "Invalid kyc status"
        end
      end

      # Last acted by
      #
      # * Author: Kedar, Puneet
      # * Date: 12/10/2017
      # * Reviewed By: Sunil
      #
      # @return [String]
      #
      def last_acted_by
        if (@user_kyc_detail.last_acted_by.to_i > 0)
          return Admin.where(id: @user_kyc_detail.last_acted_by).first.name
        elsif (@user_kyc_detail.last_acted_by.to_i == Admin::AUTO_APPROVE_ADMIN_ID)
          GlobalConstant::Admin.auto_approved_admin_name
        else
          return ''
        end
      end

      # Decrypt date of birth
      #
      # * Author: Kedar, Puneet
      # * Date: 12/10/2017
      # * Reviewed By: Sunil
      #
      def birthdate_d
        birthdate = local_cipher_obj.decrypt(@user_extended_detail.birthdate).data[:plaintext]
        Time.zone.strptime(birthdate, "%Y-%m-%d").strftime("%d/%m/%Y")
      end

      # Decrypt document_id number
      #
      # * Author: Kedar, Puneet
      # * Date: 12/10/2017
      # * Reviewed By: Sunil
      #
      def document_id_number_d
        local_cipher_obj.decrypt(@user_extended_detail.document_id_number).data[:plaintext]
      end

      # Decrypt nationality
      #
      # * Author: Kedar, Puneet
      # * Date: 12/10/2017
      # * Reviewed By: Sunil
      #
      def nationality_d
        local_cipher_obj.decrypt(@user_extended_detail.nationality).data[:plaintext].titleize
      end

      # Decrypt street address
      #
      # * Author: Kedar, Puneet
      # * Date: 12/10/2017
      # * Reviewed By: Sunil
      #
      def street_address_d
        @user_extended_detail.street_address.present? ?
            local_cipher_obj.decrypt(@user_extended_detail.street_address).data[:plaintext] : nil
      end

      #
      # * Author: Kedar, Puneet
      # * Date: 12/10/2017
      # * Reviewed By: Sunil
      #
      def city_d
        @user_extended_detail.city.present? ?
            local_cipher_obj.decrypt(@user_extended_detail.city).data[:plaintext] : nil
      end

      # Decrypt postal code
      #
      # * Author: Kedar, Puneet
      # * Date: 12/10/2017
      # * Reviewed By: Sunil
      #
      def postal_code_d
        @user_extended_detail.postal_code.present? ?
            local_cipher_obj.decrypt(@user_extended_detail.postal_code).data[:plaintext] : nil
      end

      # Decrypt country
      #
      # * Author: Kedar, Puneet
      # * Date: 12/10/2017
      # * Reviewed By: Sunil
      #
      def country_d
        local_cipher_obj.decrypt(@user_extended_detail.country).data[:plaintext].titleize
      end

      # Decrypt state
      #
      # * Author: Kedar, Puneet
      # * Date: 12/10/2017
      # * Reviewed By: Sunil
      #
      def state_d
        @user_extended_detail.state.present? ?
            local_cipher_obj.decrypt(@user_extended_detail.state).data[:plaintext] : nil
      end

      # Decrypt document_id url
      #
      # * Author: Kedar, Puneet
      # * Date: 12/10/2017
      # * Reviewed By: Sunil
      #
      def document_id_file_path_d
        local_cipher_obj.decrypt(@user_extended_detail.document_id_file_path).data[:plaintext]
      end

      # Decrypt selfie url
      #
      # * Author: Kedar, Puneet
      # * Date: 12/10/2017
      # * Reviewed By: Sunil
      #
      def selfie_file_path_d
        local_cipher_obj.decrypt(@user_extended_detail.selfie_file_path).data[:plaintext]
      end

      # Decrypt residence proof url
      #
      # * Author: Kedar, Puneet
      # * Date: 12/10/2017
      # * Reviewed By: Sunil
      #
      def residence_proof_file_path_d
        @user_extended_detail.residence_proof_file_path.present? ?
            local_cipher_obj.decrypt(@user_extended_detail.residence_proof_file_path).data[:plaintext] :
            nil
      end

      # Decrypt investor proof urls
      #
      # * Author: Pankaj
      # * Date: 26/04/2018
      # * Reviewed By:
      #
      def investor_proofs_file_path_d
        @user_extended_detail.investor_proof_files_path.present? ?
            local_cipher_obj.decrypt(@user_extended_detail.investor_proof_files_path).data[:plaintext] :
            []
      end

      # local cipher obj
      #
      # * Author: Kedar, Puneet
      # * Date: 12/10/2017
      # * Reviewed By: Sunil
      #
      def local_cipher_obj
        @local_cipher_obj ||= LocalCipher.new(@kyc_salt_d)
      end

      # get document_id url
      #
      # * Author: Kedar, Puneet
      # * Date: 12/10/2017
      # * Reviewed By: Sunil
      #
      def document_id_file_url
        rotation_angle = @user_kyc_comparison_detail.document_dimensions[:rotation_angle].to_s
        doc_file_path = document_id_file_path_d
        doc_file_path += "_#{rotation_angle}" if rotation_angle.present?
        get_url(doc_file_path)
      end

      # get selfie url
      #
      # * Author: Kedar, Puneet
      # * Date: 12/10/2017
      # * Reviewed By: Sunil
      #
      def selfie_file_url
        rotation_angle = @user_kyc_comparison_detail.selfie_dimensions[:rotation_angle].to_s
        selfie_file_path = selfie_file_path_d
        selfie_file_path += "_#{rotation_angle}" if rotation_angle.present?
        get_url(selfie_file_path)
      end

      # get residence url
      #
      # * Author: Kedar, Puneet
      # * Date: 12/10/2017
      # * Reviewed By: Sunil
      #
      def residence_proof_file_url
        get_url(residence_proof_file_path_d)
      end

      # get Investor proofs documents url
      #
      # * Author: Pankaj
      # * Date: 26/04/2018
      # * Reviewed By:
      #
      def investor_proof_files_urls
        urls = []
        investor_proofs_file_path_d.each {|x| urls << get_url(x)}
        urls
      end

      # Get file urls
      #
      # * Author: Kedar, Puneet
      # * Date: 12/10/2017
      # * Reviewed By: Sunil
      #
      def get_url(s3_path)
        return '' unless s3_path.present?

        Aws::S3Manager.new('kyc', 'admin').
            get_signed_url_for(GlobalConstant::Aws::Common.kyc_bucket, s3_path)
      end

      # Error Response
      #
      # * Author: Kedar
      # * Date: 14/10/2017
      # * Reviewed By: Sunil
      #
      # @return [Result::Base]
      #
      def err_response(err, display_text = 'Invalid Case.')
        error_with_data(
            err,
            display_text,
            display_text,
            GlobalConstant::ErrorAction.default,
            {}
        )
      end

      # Case Reopening is under process or not
      #
      # * Author: Pankaj
      # * Date: 14/05/2018
      # * Reviewed By:
      #
      # @return [Integer] - 0/1
      #
      def is_case_reopening_under_process?
        under_process = 0
        # Client has opted for whitelisting & kyc is approved, then only unwhitelisting would happen in background.
        # So check for any open edit kyc requests
        if @client.is_whitelist_setup_done? && @user_kyc_detail.kyc_approved?
          under_process = EditKycRequests.under_process.where(case_id: @user_kyc_detail.id).exists?.to_i
        end

        under_process
      end

      # Is Whitelist confirmation still to happen
      #
      # * Author: Aman
      # * Date: 21/05/2018
      # * Reviewed By:
      #
      # @return [Boolean] - True/False
      #
      def whitelist_confirmation_pending
        (@client.is_whitelist_setup_done? && @user_kyc_detail.kyc_approved? && !@user_kyc_detail.whitelist_confirmation_done?)
      end

      # Fetch client pass setting
      #
      # * Author: Aniket
      # * Date: 12/07/2018
      # * Reviewed By:
      #
      # Sets @client_kyc_pass_setting
      #
      def fetch_client_pass_setting
        @client_kyc_pass_setting ||= if @user_kyc_comparison_detail.client_kyc_pass_settings_id.to_i > 0
                                     ClientKycPassSetting.where(id: @user_kyc_comparison_detail.client_kyc_pass_settings_id).first
                                   else
                                     ClientKycPassSetting.get_active_setting_from_memcache(@client_id)
                                   end
      end

      # Fetch user kyc comparison setting
      #
      # * Author: Aniket
      # * Date: 12/07/2018
      # * Reviewed By:
      #
      # Sets @user_kyc_comparison_detail
      #
      def fetch_user_kyc_comparison_detail
        @user_kyc_comparison_detail = UserKycComparisonDetail.get_by_ued_from_memcache(@user_extended_detail.id)
      end

    end

  end
end
