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
        @approved_user_ids = []
        @users = {}
        @user_kyc_details = {}
      end

      # public method to update status of pending cynopsis state users
      #
      # * Author: Aman
      # * Date: 24/10/2017
      # * Reviewed By: Sunil
      #
      def perform
        return if GlobalConstant::TokenSale.is_sale_ended?

        UserKycDetail.where(cynopsis_status: GlobalConstant::UserKycDetail.pending_cynopsis_status).find_in_batches(batch_size: 500) do |batches|

          batches.each do |user_kyc_detail|
            process_user_kyc_details(user_kyc_detail)
          end

          get_users

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
      # Sets @approved_user_ids, @denied_user_ids, @user_kyc_details
      #
      def process_user_kyc_details(user_kyc_detail)

        r = Cynopsis::Customer.new().check_status({rfrID: user_kyc_detail.cynopsis_user_id})
        Rails.logger.info("-- call_cynopsis_check_status_api response: #{r.inspect}")
        return unless r.success?

        response_hash = ((r.data || {})[:response] || {})
        user_kyc_detail.cynopsis_status = GlobalConstant::UserKycDetail.get_cynopsis_status(response_hash['approval_status'].to_s)

        if user_kyc_detail.changed?
          user_kyc_detail.save!

          if user_kyc_detail.kyc_approved?
            @approved_user_ids << user_kyc_detail.user_id
          elsif user_kyc_detail.kyc_denied?
            @denied_user_ids << user_kyc_detail.user_id
          end
          @user_kyc_details[user_kyc_detail.user_id] = user_kyc_detail

        end

      end

      # collect all users
      #
      # * Author: Aman
      # * Date: 24/10/2017
      # * Reviewed By: Sunil
      #
      # Sets @users
      #
      def get_users

        return if (@denied_user_ids+@approved_user_ids).blank?

        @users = User.where(id: (@denied_user_ids+@approved_user_ids)).select(:email, :id).index_by(&:id)

      end

      # Send denied email
      #
      # * Author: Aman
      # * Date: 24/10/2017
      # * Reviewed By: Sunil
      #
      def send_denied_email
        return if @denied_user_ids.blank?

        @denied_user_ids.each do |user_id|

          user = @users[user_id]
          Email::HookCreator::SendTransactionalMail.new(
              email: user.email,
              template_name: GlobalConstant::PepoCampaigns.kyc_denied_template,
              template_vars: {}
          ).perform

        end

        User.where(id: @denied_user_ids).update_all(bt_name: nil, updated_at: Time.now.to_s(:db))
        User.bulk_flush(@denied_user_ids)
      end

      # Send approved email
      #
      # * Author: Aman
      # * Date: 24/10/2017
      # * Reviewed By: Sunil
      #
      def send_approved_email
        # TODO AFTER WHITELISTING - remove this.
        return if @approved_user_ids.blank?

        @approved_user_ids.each do |user_id|

          user = @users[user_id]
          Email::HookCreator::SendTransactionalMail.new(
              email: user.email,
              template_name: GlobalConstant::PepoCampaigns.kyc_approved_template,
              template_vars: {
                  token_sale_participation_phase: @user_kyc_details[user_id].token_sale_participation_phase,
                  is_sale_active: GlobalConstant::TokenSale.is_general_sale_interval?
              }
          ).perform

        end

      end


    end
  end
end