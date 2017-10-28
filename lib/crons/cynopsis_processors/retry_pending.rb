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
      # Sets @approved_user_ids, @denied_user_ids, @user_kyc_details, @users
      #
      def reset_data
        @approved_user_ids, @denied_user_ids, @user_kyc_details, @users = [], [], {}, {}
      end

      # public method to update status of pending cynopsis state users
      #
      # * Author: Aman
      # * Date: 24/10/2017
      # * Reviewed By: Sunil
      #
      def perform
        return if Time.now >= GlobalConstant::TokenSale.general_access_end_date

        UserKycDetail.where(cynopsis_status: GlobalConstant::UserKycDetail.pending_cynopsis_status).find_in_batches(batch_size: 500) do |batches|

          batches.each do |user_kyc_detail|
            process_user_kyc_details(user_kyc_detail)
          end

          next if @user_kyc_details.blank?
          all_user_ids = @approved_user_ids + @denied_user_ids
          @users = User.where(id: all_user_ids).select(:email, :id).all.index_by(&:id)

          send_aproved_email if @approved_user_ids.present?
          send_denied_email if @denied_user_ids.present?

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
            @user_kyc_details[user_kyc_detail.user_id] = user_kyc_detail
          elsif user_kyc_detail.kyc_denied?
            @denied_user_ids << user_kyc_detail.user_id
            @user_kyc_details[user_kyc_detail.user_id] = user_kyc_detail
          end

        end

      end

      # Send approved email
      #
      # * Author: Aman
      # * Date: 24/10/2017
      # * Reviewed By: Sunil
      #
      def send_aproved_email
        is_sale_active = GlobalConstant::TokenSale.is_sale_active?

        @approved_user_ids.each do |user_id|
          user_kyc_detail = @user_kyc_details[user_id]
          user = @users[user_id]

          Email::HookCreator::SendTransactionalMail.new(
              email: user.email,
              template_name: GlobalConstant::PepoCampaigns.kyc_approved_template,
              template_vars: {
                  token_sale_participation_phase: user_kyc_detail.token_sale_participation_phase,
                  is_sale_active: is_sale_active
              }
          ).perform

        end

      end


      # Send denied email
      #
      # * Author: Aman
      # * Date: 24/10/2017
      # * Reviewed By: Sunil
      #
      def send_denied_email

        @denied_user_ids.each do |user_id|
          user = @users[user_id]

          Email::HookCreator::SendTransactionalMail.new(
              email: user.email,
              template_name: GlobalConstant::PepoCampaigns.kyc_denied_template,
              template_vars: {}
          ).perform

        end

      end


    end
  end
end