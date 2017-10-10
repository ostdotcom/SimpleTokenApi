class EstablishSimpleTokenApiDbConnection < ApplicationRecord
  self.abstract_class = true

  def self.config_key
    "#{Rails.env}"
  end

  self.establish_connection(config_key.to_sym)
end
