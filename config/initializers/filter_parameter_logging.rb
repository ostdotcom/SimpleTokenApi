# Be sure to restart your server when you modify this file.

# Configure sensitive parameters which will be filtered from the log file.
Rails.application.config.filter_parameters += [:password, :first_name, :last_name, :birthdate, :street_address, :city, :state, :country,
                                               :postal_code, :ethereum_address, :estimated_participation_amount, :passport_number, :nationality,
                                               :token]
