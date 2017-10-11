class EstablishSimpleTokenUserDbConnection < ApplicationRecord
  self.abstract_class = true

  def self.config_key
    "simple_token_user_#{Rails.env}"
  end

  self.establish_connection(config_key.to_sym)
end
