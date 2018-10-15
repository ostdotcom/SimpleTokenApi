class WebhookSendLog < EstablishOstKycWebhookDbConnection

  enum status: {
      GlobalConstant::WebhookSendLog.unprocessed_status => 1,
      GlobalConstant::WebhookSendLog.processed_status => 2,
      GlobalConstant::WebhookSendLog.failed_status => 3,
      GlobalConstant::WebhookSendLog.expired_status => 4,
      GlobalConstant::WebhookSendLog.not_valid_status => 5
  }

  scope :to_be_processed, -> {where(status: [GlobalConstant::WebhookSendLog.unprocessed_status,
                                     GlobalConstant::WebhookSendLog.failed_status])}


end
