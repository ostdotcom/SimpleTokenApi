module Crons
  module AmlProcessors
    class Search

      include Util::ResultHelper

      # Initialize
      #
      # * Author: Tejas
      # * Date: 07/01/2019
      # * Reviewed By:
      #
      # @return [Crons::AmlProcessors::Search]
      #
      def initialize(params)
        @cron_identifier = params[:cron_identifier].to_s

        @aml_search_obj = nil
        @user_kyc_detail = nil
        @user_extended_detail = nil
        @aml_matches = []
      end

      # Perform
      #
      # * Author: Tejas
      # * Date: 07/01/2019
      # * Reviewed By:
      #
      # @return [Result::Base]
      #
      def perform

        fetch_aml_search_obj
        return success if @aml_search_obj.nil?

        begin
          r = fetch_and_validate_user_data
          return r unless r.success?

          r = execute_search
          return r unless r.success?

          r = execute_match
          return r unless r.success?

          r = update_aml_status
          return r unless r.success?

          r = mark_processed
          return r unless r.success?

          send_manual_review_needed_email

          success
        rescue => e
          r = error_with_identifier('internal_server_error', 'c_ap_s_p_1',
                                    [], 'Exception in process Aml Search',
                                    {message: e.message, backtrace: e.backtrace})
          update_aml_search_as_failed(r)
        end
      end

      private

      # Fetch records on which aml search is to be performed
      #
      # * Author: Tejas
      # * Date: 08/01/2019
      # * Reviewed By:
      #
      # @sets @aml_search_obj
      #
      def fetch_aml_search_obj
        AmlSearch.where(lock_id: nil).to_be_processed.
            order(id: :asc).limit(1).update_all(lock_id: lock_id)

        @aml_search_obj = AmlSearch.to_be_processed.where(lock_id: lock_id).last
      end

      # Fetch And Validate User Data
      #
      # * Author: Tejas
      # * Date: 08/01/2019
      # * Reviewed By:
      #
      # @return [Result::Base]
      #
      def fetch_and_validate_user_data
        @user_extended_detail = UserExtendedDetail.where(id: @aml_search_obj.user_extended_detail_id).first
        @user_kyc_detail = UserKycDetail.get_from_memcache(@user_extended_detail.user_id)
        if @user_kyc_detail.blank? || (@user_kyc_detail.status != GlobalConstant::UserKycDetail.active_status) ||
            (@user_kyc_detail.user_extended_detail_id != @aml_search_obj.user_extended_detail_id)
          @aml_search_obj.status = GlobalConstant::AmlSearch.deleted_status
          @aml_search_obj.save! if @aml_search_obj.changed?
          return error_with_identifier('could_not_proceed',
                                       'c_ap_s_favud_1'
          )
        end
        success
      end

      # Execute Search
      #
      # * Author: Tejas
      # * Date: 08/01/2019
      # * Reviewed By:
      #
      # @return [Result::Base]
      #
      def execute_search
        if @aml_search_obj.steps_done_array.include?(GlobalConstant::AmlSearch.search_step_done)
          @aml_matches = AmlMatch.where(aml_search_uuid: @aml_search_obj.uuid).all
          return success
        end

        r = process_search(aml_search_params)
        if r.success?
          r.data[:aml_response][:matches].each do |aml_match|
            @aml_matches << create_an_entry_in_aml_match(aml_match)
          end
        else
          update_aml_search_as_failed(r)
          return error_with_identifier('could_not_proceed', 'c_ap_s_es_1')
        end

        mark_step_done(GlobalConstant::AmlSearch.search_step_done)
        success
      end

      # Execute Match
      #
      # * Author: Tejas
      # * Date: 08/01/2019
      # * Reviewed By:
      #
      # @return [Result::Base]
      #
      def execute_match
        return success if @aml_search_obj.steps_done_array.include?(GlobalConstant::AmlSearch.pdf_step_done)

        @aml_matches.each do |aml_match|
          if aml_match.pdf_path.nil?
            r = process_match(aml_match)
            return r unless r.success?
          end
        end

        mark_step_done(GlobalConstant::AmlSearch.pdf_step_done)
        success
      end

      # Update Aml Search
      #
      # * Author: Tejas
      # * Date: 08/01/2019
      # * Reviewed By:
      #
      # @sets @user_kyc_detail, @return [Result::Base]
      #
      def update_aml_status
        return success if @user_kyc_detail.case_closed?

        if @aml_matches.blank?
          @user_kyc_detail.aml_status = GlobalConstant::UserKycDetail.cleared_aml_status
        else
          return success if @user_kyc_detail.aml_status == GlobalConstant::UserKycDetail.pending_aml_status
          @user_kyc_detail.aml_status = GlobalConstant::UserKycDetail.pending_aml_status
        end

        @user_kyc_detail.last_acted_by = Admin::AUTO_APPROVE_ADMIN_ID
        @user_kyc_detail.last_acted_timestamp = Time.now.to_i

        if @user_kyc_detail.changed?
          @user_kyc_detail.save!(touch: false)
          send_approved_email if @user_kyc_detail.kyc_approved?
          enqueue_job
        end

        success
      end

      # Mark Processed
      #
      # * Author: Tejas
      # * Date: 08/01/2019
      # * Reviewed By:
      #
      # @sets @aml_search_obj, @return [Result::Base]
      #
      def mark_processed
        @aml_search_obj.status = GlobalConstant::AmlSearch.processed_status
        @aml_search_obj.save! if @aml_search_obj.changed?
        success
      end

      # Aml Search Params
      #
      # * Author: Tejas
      # * Date: 08/01/2019
      # * Reviewed By:
      #
      def aml_search_params
        {
            "first_name" => @user_extended_detail.first_name,
            "last_name" => @user_extended_detail.last_name,
            "birthdate" => local_cipher_obj.decrypt(@user_extended_detail.birthdate).data[:plaintext],
            "country" => local_cipher_obj.decrypt(@user_extended_detail.country).data[:plaintext]
        }
      end

      # Make a api call to accuris search
      #
      # * Author: Tejas
      # * Date: 08/01/2019
      # * Reviewed By:
      #
      # Returns Result::Base
      #
      def process_search(params)
        response = Aml::Search::Persons.new.data_by_query(params)
        create_an_entry_in_aml_log(GlobalConstant::AmlLog.person_search_request_type, response)
        response
      end

      # Mark Step Done
      #
      # * Author: Tejas
      # * Date: 08/01/2019
      # * Reviewed By:
      #
      # @sets @aml_search_obj
      #
      def mark_step_done(step)
        @aml_search_obj.send("set_#{step}")
        @aml_search_obj.save! if @aml_search_obj.changed?
      end

      # Mark aml status as approve
      #
      # * Author: Tejas
      # * Date: 08/01/2019
      # * Reviewed By:
      #
      # @sets @user_kyc_detail
      #
      def mark_aml_status_as_approved
        @user_kyc_detail.aml_status = GlobalConstant::UserKycDetail.approved_aml_status
        @user_kyc_detail.save! if @user_kyc_detail.changed?
      end

      # Process Match
      #
      # * Author: Tejas
      # * Date: 08/01/2019
      # * Reviewed By:
      #
      # Returns [Boolean] (true/false)
      #
      def process_match(aml_match)
        get_pdf_response = get_pdf_for_match(aml_match.qr_code)

        if get_pdf_response.success?
          file_path = upload_pdf(get_pdf_response.data[:aml_response], aml_match.qr_code)
          update_an_entry_in_aml_match(aml_match, file_path)
        else
          update_aml_search_as_failed(get_pdf_response)
          return error_with_identifier('could_not_proceed',
                                       'c_ap_s_pm_1'
          )
        end

        success
      end

      # Mark aml status as Failed
      #
      # * Author: Tejas
      # * Date: 08/01/2019
      # * Reviewed By:
      #
      # @sets @aml_search_obj
      #
      def update_aml_search_as_failed(response)
        @aml_search_obj.status = GlobalConstant::AmlSearch.failed_status
        @aml_search_obj.lock_id = nil
        @aml_search_obj.retry_count = @aml_search_obj.retry_count + 1
        @aml_search_obj.save! if @aml_search_obj.changed?

        send_failed_mail(response)
      end

      # Get Pdf For Match
      #
      # * Author: Tejas
      # * Date: 08/01/2019
      # * Reviewed By:
      #
      # Returns Result::Base
      #
      def get_pdf_for_match(qr_code)
        response = Aml::Search::Persons.new.pdf_by_qr_code({'qr_code' => qr_code})
        create_an_entry_in_aml_log(GlobalConstant::AmlLog.person_get_profile_pdf_request_type, response)
        response
      end

      # Create File Path To Upload A Pdf
      #
      # * Author: Tejas
      # * Date: 08/01/2019
      # * Reviewed By:
      #
      # Returns [String]
      #
      def pdf_file_path(match_id)
        "aml_pdf_data/#{@user_kyc_detail.client_id}/#{@aml_search_obj.user_kyc_detail_id}/#{@aml_search_obj.user_extended_detail_id}/#{match_id}"
      end

      # Upload Pdf To S3
      #
      # * Author: Tejas
      # * Date: 08/01/2019
      # * Reviewed By:
      #
      # Returns [String] s3_file_name
      #
      def upload_pdf(pdf_bytes, qr_code)
        s3_file_path = pdf_file_path(qr_code)
        encoded_qr_code_for_pdf = Util::CommonValidateAndSanitize.encode_string_to_hexadecimal_string(qr_code)
        pdf_bytes = pdf_bytes.to_s.gsub(/Title<FEFF[A-Z0-9]*>/, "Title<FEFF#{encoded_qr_code_for_pdf}>")
        puts "Pdf uploading started"

        Aws::S3Manager.new('kyc', 'user').
            store(s3_file_path, pdf_bytes, GlobalConstant::Aws::Common.kyc_bucket)

        s3_file_path
      end

      # Create An Entry In Aml Log
      #
      # * Author: Tejas
      # * Date: 08/01/2019
      # * Reviewed By:
      #
      def create_an_entry_in_aml_log(request_type, data)
        e_data = Rails.env.production? ? local_cipher_obj.encrypt(data.to_json).data[:ciphertext_blob] : data.to_json
        AmlLog.create!(aml_search_uuid: @aml_search_obj.uuid, request_type: request_type, response: e_data)
      rescue => e
        ApplicationMailer.notify(
            body: e.backtrace,
            data: {search_id: @aml_search_obj.id, message: e.message},
            subject: "Could not create AmlLog"
        ).deliver
      end

      # Create An Entry In Aml Match
      #
      # * Author: Tejas
      # * Date: 08/01/2019
      # * Reviewed By:
      #
      def create_an_entry_in_aml_match(match)
        e_data = Rails.env.production? ? local_cipher_obj.encrypt(match.to_json).data[:ciphertext_blob] : match.to_json
        match_id = match[:person][:match_id]
        qr_code = match[:person][:id]

        raise "Invalid match response from acuris- #{match}" if qr_code.blank?
        AmlMatch.create!(aml_search_uuid: @aml_search_obj.uuid,
                         match_id: match_id,
                         qr_code: qr_code,
                         status: GlobalConstant::AmlMatch.unprocessed_status,
                         data: e_data,
                         pdf_path: nil)
      end

      # Update An Entry In Aml Match
      #
      # * Author: Tejas
      # * Date: 08/01/2019
      # * Reviewed By:
      #
      # @sets match
      #
      def update_an_entry_in_aml_match(aml_match, s3_pdf_path)
        encr_s3_pdf_path = local_cipher_obj.encrypt(s3_pdf_path).data[:ciphertext_blob]
        aml_match.pdf_path = encr_s3_pdf_path
        aml_match.save! if aml_match.changed?
      end

      # Send Failed Mail
      #
      # * Author: Tejas
      # * Date: 08/01/2019
      # * Reviewed By:
      #
      def send_failed_mail(response)
        ApplicationMailer.notify(
            to: GlobalConstant::Email.default_to,
            body: "Call to Acuris Api failed",
            data: {aml_search_id: @aml_search_obj.id, response: response.inspect},
            subject: "Something went wrong with Acuris Api."
        ).deliver
      end

      # Get Local Cipher Object For User
      #
      # * Author: Tejas
      # * Date: 08/01/2019
      # * Reviewed By:
      #
      # @return [LocalCipher]
      #
      def local_cipher_obj
        @local_cipher_obj ||= begin
          r = Aws::Kms.new('kyc', 'admin').decrypt(@user_extended_detail.kyc_salt)
          raise r unless r.success?
          LocalCipher.new(r.data[:plaintext])
        end
      end

      # Do remaining task in sidekiq
      #
      # * Author: Tejas
      # * Date: 16/10/2018
      # * Reviewed By:
      #
      def enqueue_job
        admin = {}
        if @user_kyc_detail.last_acted_by.to_i > 0
          admin = Admin.get_from_memcache(@user_kyc_detail.last_acted_by).get_hash
        end

        BgJob.enqueue(
            WebhookJob::RecordEvent,
            {
                client_id: @user_kyc_detail.client_id,
                event_source: GlobalConstant::Event.kyc_system_source,
                event_name: GlobalConstant::Event.kyc_status_update_name,
                event_data: {
                    user_kyc_detail: @user_kyc_detail.get_hash,
                    admin: admin
                },
                event_timestamp: Time.now.to_i
            }
        )

      end

      # Send approved email
      #
      # * Author: Tejas
      # * Date: 16/10/2018
      # * Reviewed By:
      #
      def send_approved_email

        client = Client.get_from_memcache(@user_kyc_detail.client_id)
        user = User.get_from_memcache(@user_kyc_detail.user_id)

        return if !client.is_email_setup_done? || client.is_whitelist_setup_done? ||
            client.is_st_token_sale_client? || (!client.client_kyc_config_detail.auto_send_kyc_approve_email?)

        Email::HookCreator::SendTransactionalMail.new(
            client_id: client.id,
            email: user.email,
            template_name: GlobalConstant::PepoCampaigns.kyc_approved_template,
            template_vars: GlobalConstant::PepoCampaigns.kyc_approve_default_template_vars(client.id)
        ).perform

      end

      # Send Manual review needed email to admins
      #
      # * Author: Aman
      # * Date: 24/01/2019
      # * Reviewed By:
      #
      #
      def send_manual_review_needed_email
        return if (@aml_search_obj.status != GlobalConstant::AmlSearch.processed_status) &&
            GlobalConstant::UserKycDetail.aml_approved_statuses.include?(@user_kyc_detail.aml_status) &&
            !@user_kyc_detail.send_manual_review_needed_email?

        GlobalConstant::Admin.send_manual_review_needed_email(@user_kyc_comparison_detail.client_id,
                                                              {template_variables: {}})
      end

      # Lock Id for table
      #
      # * Author: Tejas
      # * Date: 08/01/2019
      # * Reviewed By:
      #
      # @returns [String] lock_id
      #
      def lock_id
        @lock_id ||= "#{@cron_identifier}_#{Time.now.to_f}"
      end

    end
  end
end
