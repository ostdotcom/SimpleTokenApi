class EstablishOstKycWebhookDbConnection < ApplicationRecord
  self.abstract_class = true

  def self.config_key
    "ost_kyc_webhook_#{Rails.env}"
  end

  self.establish_connection(config_key.to_sym)
end