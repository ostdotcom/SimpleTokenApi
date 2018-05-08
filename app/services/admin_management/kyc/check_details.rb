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

        fetch_surround_kyc_ids

        r = fetch_user_extended_detail
        return r unless r.success?

        r = decrypt_kyc_salt
        return r unless r.success?

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
        return err_response('am_k_cd_2') if @user_kyc_detail.blank?

        @user = User.where(client_id: @client_id, id: @user_kyc_detail.user_id).first
        return err_response('am_k_cd_3') if @user.blank?

        success
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
        ar_relation = UserKycDetail.where(client_id: @client_id)
        ar_relation = ar_relation.filter_by(@filters)
        ar_relation = ar_relation.select(:id)

        if @sortings.present? && @sortings[:sort_order] == 'asc'
          kyc_1 = ar_relation.where("id > ?", @case_id).first
          kyc_2 = ar_relation.where("id < ?", @case_id).last
          @next_kyc_id = kyc_1.id if kyc_1.present?
          @previous_kyc_id = kyc_2.id if kyc_2.present?
        else
          kyc_1 = ar_relation.where("id < ?", @case_id).first
          kyc_2 = ar_relation.where("id > ?", @case_id).last
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

        @api_response_data = {
            user_detail: user_detail,
            case_detail: case_detail,
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
        {
            first_name: @user_extended_detail.first_name,
            last_name: @user_extended_detail.last_name,
            email: @user.email,
            submitted_at: Util::DateTimeHelper.get_formatted_time(@user_extended_detail.created_at.to_i),
            birthdate: birthdate_d,
            document_id_number: document_id_number_d,
            nationality: nationality_d,
            street_address: street_address_d,
            city: city_d,
            state: state_d,
            postal_code: postal_code_d,
            country: country_d,
            geoip_data: @user_geoip_data,
            document_id_file_url: document_id_file_url,
            selfie_file_url: selfie_file_url,
            residence_proof_file_url: residence_proof_file_url,
            investor_proof_files_url: investor_proof_files_urls
        }
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
            cynopsis_status: @user_kyc_detail.cynopsis_status,
            retry_cynopsis: (@user_kyc_detail.cynopsis_status == GlobalConstant::UserKycDetail.failed_cynopsis_status).to_i,
            submission_count: @user_kyc_detail.submission_count.to_i,
            is_re_submitted: @user_kyc_detail.is_re_submitted?,
            is_duplicate: @user_kyc_detail.show_duplicate_status.to_i,
            last_acted_by: last_acted_by,
            whitelist_status: @user_kyc_detail.whitelist_status,
            last_issue_email_sent: @user_kyc_detail.admin_action_types_array,
            is_case_closed: @user_kyc_detail.case_closed?.to_i,
            can_reopen_case: (@user_kyc_detail.case_closed? && (@user_kyc_detail.cynopsis_status != GlobalConstant::UserKycDetail.rejected_cynopsis_status)).to_i
        }
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
        (@user_kyc_detail.last_acted_by.to_i > 0) ?
            Admin.where(id: @user_kyc_detail.last_acted_by).first.name :
            ''
      end

      # Decrypt date of birth
      #
      # * Author: Kedar, Puneet
      # * Date: 12/10/2017
      # * Reviewed By: Sunil
      #
      def birthdate_d
        local_cipher_obj.decrypt(@user_extended_detail.birthdate).data[:plaintext]
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
        get_url(document_id_file_path_d)
      end

      # get selfie url
      #
      # * Author: Kedar, Puneet
      # * Date: 12/10/2017
      # * Reviewed By: Sunil
      #
      def selfie_file_url
        get_url(selfie_file_path_d)
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
        investor_proofs_file_path_d.each{|x| urls << get_url(x)}
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
      def err_response(err, display_text = 'Invalid request.')
        error_with_data(
            err,
            display_text,
            display_text,
            GlobalConstant::ErrorAction.default,
            {}
        )
      end

    end

  end

end