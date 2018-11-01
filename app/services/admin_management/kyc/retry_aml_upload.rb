module AdminManagement

  module Kyc

    class RetryAmlUpload < ServicesBase

      # Initialize
      #
      # * Author: Aman
      # * Date: 25/04/2018
      # * Reviewed By:
      #
      # @params [Integer] client_id (mandatory) - logged in admin's client id
      # @params [Integer] id (mandatory) - user kyc detail id
      #
      # @params [Integer] admin_id (optional) - logged in admin (not passed when called by a cron)
      # @params [Boolean] cron_job (optional) - true if called by cron job
      #
      # @return [AdminManagement::Kyc::RetryAmlUpload]
      #
      def initialize(params)
        super

        @client_id = @params[:client_id]
        @case_id = @params[:id]

        @admin_id = @params[:admin_id]
        @cron_job = @params[:cron_job]

        @user_kyc_detail, @user_extended_detail = nil, nil
        @aml_status = GlobalConstant::UserKycDetail.failed_aml_status

        @kyc_salt_d = nil
      end

      # perform aml add or update for kyc user
      #
      # * Author: Aman
      # * Date: 25/04/2018
      # * Reviewed By:
      #
      # @return [Result::Base]
      #
      def perform
        r = validate
        return r unless r.success?

        r = fetch_and_validate_client
        return r unless r.success?

        if !is_a_cron_task?
          r = fetch_and_validate_admin
          return r unless r.success?
        end

        fetch_user_kyc

        r = validate_user_kyc
        return r unless r.success?

        fetch_user_extended_detail

        decrypt_kyc_salt

        r = call_aml_api
        return r unless r.success?

        success
      end

      private

      # Fetch user kyc obj
      #
      # * Author: Aman
      # * Date: 25/04/2018
      # * Reviewed By:
      #
      # Sets @user_kyc_detail
      #
      def fetch_user_kyc
        @user_kyc_detail = UserKycDetail.where(id: @case_id).first
      end

      # Validate if aml upload should be retried for user kyc obj
      #
      # * Author: Aman
      # * Date: 25/04/2018
      # * Reviewed By:
      #
      # @return [Result::Base]
      #
      def validate_user_kyc

        return error_with_data(
            'am_k_rcu_vuk_1',
            "Invalid Request For User kyc",
            "Invalid Request For User kyc",
            GlobalConstant::ErrorAction.default,
            {},
            {}
        ) if @user_kyc_detail.blank? || @user_kyc_detail.inactive_status?

        return error_with_data(
            'am_k_rcu_vuk_2',
            "User kyc is already uploaded in aml",
            "user kyc has been added to aml",
            GlobalConstant::ErrorAction.default,
            {},
            {}
        ) if @user_kyc_detail.aml_status != GlobalConstant::UserKycDetail.failed_aml_status

        success
      end

      # Fetch user extended detail obj
      #
      # * Author: Aman
      # * Date: 25/04/2018
      # * Reviewed By:
      #
      # Sets @user_extended_detail
      #
      def fetch_user_extended_detail
        @user_extended_detail = UserExtendedDetail.where(id: @user_kyc_detail.user_extended_detail_id).first
      end

      # aml add or update
      #
      # * Author: Aman
      # * Date: 25/04/2018
      # * Reviewed By:
      #
      # @return [Result::Base]
      #
      def call_aml_api
        r = @user_kyc_detail.aml_user_id.blank? ? create_aml_case : update_aml_case
        Rails.logger.info("-- retry for call_aml_api r: #{r.inspect}")

        if !r.success?
          # dont log activity if it is a cron task
          log_to_user_activity(r) if !is_a_cron_task?
          save_aml_status

          return error_with_data(
              'am_k_rcu_cca_1',
              "There was some error in aml update",
              "Unable to update in aml. There was some error.",
              GlobalConstant::ErrorAction.default,
              {},
              {}
          )
        end

        response_hash = ((r.data || {})[:response] || {})
        @aml_status = GlobalConstant::UserKycDetail.get_aml_status(response_hash['approval_status'].to_s)
        @user_kyc_detail.aml_user_id = get_aml_user_id
        save_aml_status

        success
      end

      # Decrypt kyc salt
      #
      # * Author: Aman
      # * Date: 25/04/2018
      # * Reviewed By:
      #
      # Sets @kyc_salt_d
      #
      def decrypt_kyc_salt
        Rails.logger.info('-- decrypt_kyc_salt')

        r = Aws::Kms.new('kyc', 'admin').decrypt(@user_extended_detail.kyc_salt)
        fail 'decryption of kyc salt failed.' unless r.success?

        @kyc_salt_d = r.data[:plaintext]
      end

      # Create user in aml
      #
      # * Author: Aman
      # * Date: 25/04/2018
      # * Reviewed By:
      #
      # @return [Result::Base]
      #
      def create_aml_case
        Aml::Customer.new(client_id: @user_kyc_detail.client_id).create(aml_params)
      end

      # Update user in aml
      #
      # * Author: Aman
      # * Date: 25/04/2018
      # * Reviewed By:
      #
      # @return [Result::Base]
      #
      def update_aml_case
        Aml::Customer.new(client_id: @user_kyc_detail.client_id).update(aml_params, true)
      end

      # Log to user activity
      #
      # * Author: Aman
      # * Date: 25/04/2018
      # * Reviewed By:
      #
      def log_to_user_activity(response)
        UserActivityLogJob.new().perform({
                                             user_id: @user_kyc_detail.user_id,
                                             action: GlobalConstant::UserActivityLog.aml_api_error,
                                             action_timestamp: Time.now.to_i,
                                             extra_data: {
                                                 response: response.to_json
                                             }
                                         })
      end

      # local cipher obj
      #
      # * Author: Aman
      # * Date: 25/04/2018
      # * Reviewed By:
      #
      def local_cipher_obj
        @local_cipher_obj ||= LocalCipher.new(@kyc_salt_d)
      end

      # Create aml params
      #
      # * Author: Aman
      # * Date: 25/04/2018
      # * Reviewed By:
      #
      def aml_params
        date_of_birth_d = local_cipher_obj.decrypt(@user_extended_detail.birthdate).data[:plaintext]
        {
            rfrID: get_aml_user_id,
            first_name: @user_extended_detail.first_name,
            last_name: @user_extended_detail.last_name,
            country_of_residence: local_cipher_obj.decrypt(@user_extended_detail.country).data[:plaintext].upcase,
            date_of_birth:  Time.zone.strptime(date_of_birth_d, "%Y-%m-%d").strftime("%d/%m/%Y"),
            identification_type: 'PASSPORT',
            identification_number: local_cipher_obj.decrypt(@user_extended_detail.document_id_number).data[:plaintext],
            nationality: local_cipher_obj.decrypt(@user_extended_detail.nationality).data[:plaintext].upcase
        }
      end

      # Save aml response status
      #
      # * Author: Aman
      # * Date: 25/04/2018
      # * Reviewed By:
      #
      def save_aml_status
        Rails.logger.info('-- save_aml_status')
        is_already_kyc_denied_by_admin = @user_kyc_detail.kyc_denied?

        @user_kyc_detail.aml_status = @aml_status

        if @user_kyc_detail.changed?
          @user_kyc_detail.save!(touch: false)

          send_denied_email if @user_kyc_detail.kyc_denied? && !is_already_kyc_denied_by_admin

          send_approved_email if @user_kyc_detail.kyc_approved?
          enqueue_job
        end

      end

      # Get aml rfrID
      #
      # * Author: Aman
      # * Date: 25/04/2018
      # * Reviewed By:
      #
      # ts - (token sale)
      # Rails.env[0..1] - (de/sa/st/pr)
      #
      def get_aml_user_id
        @get_aml_user_id ||= @user_kyc_detail.aml_user_id.present? ? @user_kyc_detail.aml_user_id.to_s :
                                      UserKycDetail.get_aml_user_id(@user_kyc_detail.user_id)
      end

      # Send denied email
      #
      # * Author: Aman
      # * Date: 27/04/2018
      # * Reviewed By:
      #
      def send_denied_email
        return if !@client.is_email_setup_done? || @client.is_st_token_sale_client?

        user = User.where(id: @user_kyc_detail.user_id).select(:email, :id).first

        Email::HookCreator::SendTransactionalMail.new(
            client_id: @client_id,
            email: user.email,
            template_name: GlobalConstant::PepoCampaigns.kyc_denied_template,
            template_vars: {}
        ).perform

      end

      # Send approved email
      #
      # * Author: Aman
      # * Date: 27/04/2018
      # * Reviewed By:
      #
      def send_approved_email
        return if !@client.is_email_setup_done? || @client.is_whitelist_setup_done? || @client.is_st_token_sale_client?

        user = User.where(id: @user_kyc_detail.user_id).select(:email, :id).first
        client_token_sale_details_obj = ClientTokenSaleDetail.get_from_memcache(@client_id)

        Email::HookCreator::SendTransactionalMail.new(
            client_id: @client_id,
            email: user.email,
            template_name: GlobalConstant::PepoCampaigns.kyc_approved_template,
            template_vars: {
                token_sale_participation_phase: @user_kyc_detail.token_sale_participation_phase,
                is_sale_active: client_token_sale_details_obj.has_token_sale_started?
            }
        ).perform

      end

      def is_a_cron_task?
        @cron_job == true
      end

      # Get Event Source
      #
      # * Author: Tejas
      # * Date: 16/10/2018
      # * Reviewed By:
      #
      def get_event_source
        is_a_cron_task? ? GlobalConstant::Event.kyc_system_source : GlobalConstant::Event.web_source
      end

      # Do remaining task in sidekiq
      #
      # * Author: Tejas
      # * Date: 16/10/2018
      # * Reviewed By:
      #
      def enqueue_job
        BgJob.enqueue(
            RecordEventJob,
            {
                client_id: @user_kyc_detail.client_id,
                event_source: get_event_source,
                event_name: GlobalConstant::Event.kyc_status_update_name,
                event_data: {
                    user_kyc_detail: @user_kyc_detail.get_hash,
                    admin: @user_kyc_detail.get_last_acted_admin_hash
                },
                event_timestamp: Time.now.to_i
            }
        )

      end

    end

  end

end
