module Crons

  module CynopsisProcessors

    class RetryPending

      # initialize
      #
      # * Author: Aman
      # * Date: 24/10/2017
      # * Reviewed By: Sunil
      ##
      # @return [Crons::CynopsisProcessor::RetryPending]
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
      # Sets @denied_user_ids
      #
      def reset_data
        @denied_user_ids = []
      end

      # public method to update status of pending cynopsis state users
      #
      # * Author: Aman
      # * Date: 24/10/2017
      # * Reviewed By: Sunil
      #
      def perform
        Clients.all.each do |client_obj|
          @client = client_obj
          next if @client.is_st_token_sale_client?

          UserKycDetail.where(client_id: @client.id, cynopsis_status: GlobalConstant::UserKycDetail.pending_cynopsis_status).find_in_batches(batch_size: 500) do |batches|

            batches.each do |user_kyc_detail|
              process_user_kyc_details(user_kyc_detail)
            end

            send_denied_email

            reset_data
          end
        end
      end

      private

      # Update user_kyc_detail if cynopsis status changed
      #
      # * Author: Aman
      # * Date: 24/10/2017
      # * Reviewed By: Sunil
      #
      # Sets @denied_user_ids
      #
      def process_user_kyc_details(user_kyc_detail)
        is_already_kyc_denied_by_admin = user_kyc_detail.kyc_denied?

        r = Cynopsis::Customer.new(client_id: user_kyc_detail.client_id).check_status({rfrID: user_kyc_detail.cynopsis_user_id})
        Rails.logger.info("-- call_cynopsis_check_status_api response: #{r.inspect}")
        return unless r.success?

        response_hash = ((r.data || {})[:response] || {})
        user_kyc_detail.cynopsis_status = GlobalConstant::UserKycDetail.get_cynopsis_status(response_hash['approval_status'].to_s)

        if user_kyc_detail.changed?
          user_kyc_detail.save!(touch: false)

          if user_kyc_detail.kyc_denied?
            @denied_user_ids << user_kyc_detail.user_id if !is_already_kyc_denied_by_admin
          end

        end

      end

      # Send denied email
      #
      # * Author: Aman
      # * Date: 24/10/2017
      # * Reviewed By: Sunil
      #
      def send_denied_email
        return if @denied_user_ids.blank?

        User.where(id: @denied_user_ids).select(:email, :id).each do |user|

          Email::HookCreator::SendTransactionalMail.new(
              client_id: @client.id,
              email: user.email,
              template_name: GlobalConstant::PepoCampaigns.kyc_denied_template,
              template_vars: {}
          ).perform if @client.is_email_setup_done?

        end

        return unless @client.is_st_token_sale_client?

        User.where(id: @denied_user_ids).update_all(bt_name: nil, updated_at: Time.now.to_s(:db))
        User.bulk_flush(@denied_user_ids)
      end

    end

  end

end