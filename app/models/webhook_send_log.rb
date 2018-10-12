class WebhookSendLog < EstablishOstKycWebhookDbConnection

  enum status: {
      GlobalConstant::WebhookSendLog.unprocessed_status => 1,
      GlobalConstant::WebhookSendLog.failed_status => 2,
      GlobalConstant::WebhookSendLog.expired_status => 3,
      GlobalConstant::WebhookSendLog.invalid_status => 4
  }

end
