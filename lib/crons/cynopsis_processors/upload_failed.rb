module Crons

  module CynopsisProcessors

    class UploadFailed

      # initialize
      #
      # * Author: Aman
      # * Date: 24/10/2017
      # * Reviewed By: Sunil
      ##
      # @return [Crons::CynopsisProcessor::UploadFailed]
      #
      def initialize(params)
      end

      # public method to update status of pending cynopsis state users
      #
      # * Author: Aman
      # * Date: 24/10/2017
      # * Reviewed By: Sunil
      #
      def perform
        UserKycDetail.where('client_id != ?', GlobalConstant::TokenSale.st_token_sale_client_id).
            where(cynopsis_status: GlobalConstant::UserKycDetail.failed_cynopsis_status).find_in_batches(batch_size: 50) do |batches|

          batches.each do |user_kyc_detail|
            next if user_kyc_detail.inactive_status?
            params_to_retry = {
                client_id: user_kyc_detail.client_id,
                id: user_kyc_detail.id,
                cron_job: true
            }

            r = AdminManagement::Kyc::RetryCynopsisUpload.new(params_to_retry).perform

            unless r.success?
              ApplicationMailer.notify(
                  body: "Unable to upload to cynopsis for user",
                  data: {user_kyc_detail_id: user_kyc_detail.id, error: r},
                  subject: "RetryCynopsisUpload CRON TASK Failed"
              ).deliver
            end

          end

        end
      end

    end

  end

end