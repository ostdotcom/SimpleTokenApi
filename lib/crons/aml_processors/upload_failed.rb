module Crons

  module AmlProcessors

    class UploadFailed

      # initialize
      #
      # * Author: Aman
      # * Date: 24/10/2017
      # * Reviewed By: Sunil
      ##
      # @return [Crons::AmlProcessor::UploadFailed]
      #
      def initialize(params)
      end

      # public method to update status of pending aml state users
      #
      # * Author: Aman
      # * Date: 24/10/2017
      # * Reviewed By: Sunil
      #
      def perform
        UserKycDetail.where('client_id != ?', GlobalConstant::TokenSale.st_token_sale_client_id).active_kyc.
            where(aml_status: GlobalConstant::UserKycDetail.failed_aml_status).find_in_batches(batch_size: 50) do |batches|

          batches.each do |user_kyc_detail|
            params_to_retry = {
                client_id: user_kyc_detail.client_id,
                id: user_kyc_detail.id,
                cron_job: true
            }

            r = AdminManagement::Kyc::RetryAmlUpload.new(params_to_retry).perform

            unless r.success?
              ApplicationMailer.notify(
                  body: "Unable to upload to aml for user",
                  data: {user_kyc_detail_id: user_kyc_detail.id, error: r},
                  subject: "RetryAmlUpload CRON TASK Failed"
              ).deliver
            end

          end

        end
      end

    end

  end

end