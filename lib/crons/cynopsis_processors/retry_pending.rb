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
      # Sets @denied_user_ids, @approved_user_id_hash
      #
      def reset_data
        @denied_user_ids, @approved_user_id_hash = [], {}
      end

      # public method to update status of pending cynopsis state users
      #
      # * Author: Aman
      # * Date: 24/10/2017
      # * Reviewed By: Sunil
      #
      def perform
        UserKycDetail.where('client_id != ?', GlobalConstant::TokenSale.st_token_sale_client_id).
            where(cynopsis_status: GlobalConstant::UserKycDetail.pending_cynopsis_status).find_in_batches(batch_size: 500) do |batches|

          batches.each do |user_kyc_detail|
            process_user_kyc_details(user_kyc_detail)
          end

          send_denied_email
          send_approved_email

          reset_data
        end
      end

      private

      # Update user_kyc_detail if cynopsis status changed
      #
      # * Author: Aman
      # * Date: 24/10/2017
      # * Reviewed By: Sunil
      #
      # Sets @denied_user_ids, @approved_user_id_hash
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

          if user_kyc_detail.kyc_approved?
            @approved_user_id_hash[user_kyc_detail.user_id] = user_kyc_detail
          end

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

        User.where(id: @denied_user_ids).select(:email, :id).each do |user|
          client_id = user.client_id
          client = client_objs[client_id]

          Email::HookCreator::SendTransactionalMail.new(
              client_id: client_id,
              email: user.email,
              template_name: GlobalConstant::PepoCampaigns.kyc_denied_template,
              template_vars: {}
          ).perform if client.is_email_setup_done?

        end

        return unless client.is_st_token_sale_client?

        User.where(id: @denied_user_ids).update_all(bt_name: nil, updated_at: Time.now.to_s(:db))
        User.bulk_flush(@denied_user_ids)
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

        User.where(id: approved_user_ids).select(:email, :id).each do |user|
          client_id = user.client_id
          client = client_objs[client_id]
          user_kyc_detail = @approved_user_id_hash[user.id]

          next if !client.is_email_setup_done? || client.is_whitelist_setup_done? || client.is_st_token_sale_client?

          Email::HookCreator::SendTransactionalMail.new(
              client_id: client_id,
              email: user.email,
              template_name: GlobalConstant::PepoCampaigns.kyc_approved_template,
              template_vars: {
                  token_sale_participation_phase: user_kyc_detail.token_sale_participation_phase,
                  is_sale_active: client_token_sale_details_objs[client_id].has_token_sale_started?
              }
          ).perform
        end
      end

    end

  end

end