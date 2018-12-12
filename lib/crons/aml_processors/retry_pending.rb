module Crons

  module AmlProcessors

    class RetryPending

      # initialize
      #
      # * Author: Aman
      # * Date: 24/10/2017
      # * Reviewed By: Sunil
      ##
      # @return [Crons::AmlProcessor::RetryPending]
      #
      def initialize(params)
        reset_data
      end

      # Initialize variables
      #
      # * Author: Aman
      # * Date: 24/10/2017
      # * Reviewed By: Sunil
      #
      # Sets @denied_user_ids, @approved_user_id_hash
      #
      def reset_data
        @denied_user_ids, @approved_user_id_hash = [], {}
      end

      # public method to update status of pending aml state users
      #
      # * Author: Aman
      # * Date: 24/10/2017
      # * Reviewed By: Sunil
      #
      def perform
        UserKycDetail.where('client_id != ?', GlobalConstant::TokenSale.st_token_sale_client_id).active_kyc.
            where(aml_status: GlobalConstant::UserKycDetail.pending_aml_status).find_in_batches(batch_size: 10) do |batches|

          batches.each do |user_kyc_detail|
            process_user_kyc_details(user_kyc_detail)
          end

          send_denied_email
          send_approved_email

          reset_data
          return if GlobalConstant::SignalHandling.sigint_received?
        end
      end

      private

      # Update user_kyc_detail if aml status changed
      #
      # * Author: Aman
      # * Date: 24/10/2017
      # * Reviewed By: Sunil
      #
      # Sets @denied_user_ids, @approved_user_id_hash
      #
      def process_user_kyc_details(user_kyc_detail)
        is_already_kyc_denied_by_admin = user_kyc_detail.kyc_denied?

        r = Aml::Customer.new(client_id: user_kyc_detail.client_id).check_status({rfrID: user_kyc_detail.aml_user_id})
        # Rails.logger.info("-- call_aml_check_status_api response: #{r.inspect}")
        return unless r.success?

        response_hash = ((r.data || {})[:response] || {})
        user_kyc_detail.aml_status = GlobalConstant::UserKycDetail.get_aml_status(response_hash['approval_status'].to_s)

        if user_kyc_detail.changed?
          user_kyc_detail.save!(touch: false)

          if user_kyc_detail.kyc_denied?
            @denied_user_ids << user_kyc_detail.user_id if !is_already_kyc_denied_by_admin
          end

          if user_kyc_detail.kyc_approved?
            @approved_user_id_hash[user_kyc_detail.user_id] = user_kyc_detail
          end

          record_event_job(user_kyc_detail)

        end

      end

      # client objs
      #
      # * Author: Aman
      # * Date: 05/01/2018
      # * Reviewed By:
      #
      # returns [Hash] client objs indexed by id
      #
      def client_objs
        @client_objs ||= Client.all.index_by(&:id)
      end

      # client Token sale objs
      #
      # * Author: Aman
      # * Date: 27/04/2018
      # * Reviewed By:
      #
      # returns [Hash] client token sale objs indexed by client_id
      #
      def client_token_sale_details_objs
        @client_token_sale_objs ||= ClientTokenSaleDetail.all.index_by(&:client_id)
      end

      # Send denied email
      #
      # * Author: Aman
      # * Date: 24/10/2017
      # * Reviewed By: Sunil
      #
      def send_denied_email
        return if @denied_user_ids.blank?

        User.where(id: @denied_user_ids).select(:email, :id, :client_id).each do |user|
          client_id = user.client_id
          client = client_objs[client_id]

          Email::HookCreator::SendTransactionalMail.new(
              client_id: client_id,
              email: user.email,
              template_name: GlobalConstant::PepoCampaigns.kyc_denied_template,
              template_vars: {}
          ).perform if client.is_email_setup_done?

        end
      end

      # Send approved email
      #
      # * Author: Aman
      # * Date: 27/04/2018
      # * Reviewed By:
      #
      def send_approved_email
        return if @approved_user_id_hash.blank?
        approved_user_ids = @approved_user_id_hash.keys

        User.where(id: approved_user_ids).select(:email, :id, :client_id).each do |user|
          client_id = user.client_id
          client = client_objs[client_id]
          user_kyc_detail = @approved_user_id_hash[user.id]

          next if !client.is_email_setup_done? || client.is_whitelist_setup_done? || client.is_st_token_sale_client?

          Email::HookCreator::SendTransactionalMail.new(
              client_id: client_id,
              email: user.email,
              template_name: GlobalConstant::PepoCampaigns.kyc_approved_template,
              template_vars: GlobalConstant::PepoCampaigns.kyc_approve_default_template_vars(client_id)
          ).perform
        end
      end

      # record event for webhooks
      #
      # * Author: Tejas
      # * Date: 16/10/2018
      # * Reviewed By:
      #
      def record_event_job(user_kyc_detail)

        WebhookJob::RecordEvent.perform_now({
                                       client_id: user_kyc_detail.client_id,
                                       event_source: GlobalConstant::Event.kyc_system_source,
                                       event_name: GlobalConstant::Event.kyc_status_update_name,
                                       event_data: {
                                           user_kyc_detail: user_kyc_detail.get_hash,
                                           admin: user_kyc_detail.get_last_acted_admin_hash
                                       },
                                       event_timestamp: Time.now.to_i
                                   })

      end

    end

  end

end