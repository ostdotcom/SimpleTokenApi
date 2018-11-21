namespace :onetimer do

  # rake RAILS_ENV=staging onetimer:update_alternate_tokens_data

  task :update_alternate_tokens_data => :environment do
    failed_data = []

    alternate_tokens = AlternateToken.all.index_by(&:token_name)

    alternate_tokens.each do |token_name, alt_token_obj|

      next if alt_token_obj.contract_address.blank?
      r = Request::OpsApi::ThirdPartyErc20GetDecimal.new.perform({contract_address: alt_token_obj.contract_address})
      unless r.success?
        failed_data << token_name
        next
      end

      contract_decimal = r.data['numberOfDecimals'].to_i
      puts "Decimal on token_name:#{token_name} - #{contract_decimal}\n"

      alt_token_obj.number_of_decimal = contract_decimal
      alt_token_obj.save
    end
    puts "failed- #{failed_data}"


    alt_bonus_logs = AltCoinBonusLog.all

    alt_bonus_logs.each do |alt_bonus_log|
      alternate_token = alternate_tokens[alt_bonus_log.alt_token_name]

      fail 'alternate_token not found-' + alt_bonus_log.alt_token_name if alternate_token.blank?
      fail 'alternate_token contract_address not found-' + alt_bonus_log.alt_token_name if alternate_token.contract_address.blank?

      alt_bonus_log.alt_token_contract_address = alternate_token.contract_address
      alt_bonus_log.number_of_decimal = alternate_token.number_of_decimal
      alt_bonus_log.save
    end

  end
end


