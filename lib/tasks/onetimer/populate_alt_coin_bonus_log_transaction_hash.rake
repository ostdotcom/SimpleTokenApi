namespace :onetimer do

  # rake RAILS_ENV=staging onetimer:populate_alt_coin_bonus_log_transaction_hash

  task :populate_alt_coin_bonus_log_transaction_hash => :environment do

    filepath = "#{Rails.root}/lib/tasks/onetimer/alt_coin_bonus_log_transaction_hash_data.csv"

    def send_alt_coin_bonus_distribution_email(email, template_vars)
      send_mail_response = Email::Services::PepoCampaigns.new(
          ClientPepoCampaignDetail.get_from_memcache(GlobalConstant::TokenSale.st_token_sale_client_id)).
          send_transactional_email(
          email, GlobalConstant::PepoCampaigns.altdrop_sent, template_vars)

      if send_mail_response['error'].present?
        puts "error in send email without hook response- #{send_mail_response.inspect}"
        send_purchase_confirmation_email_via_hooks(email, template_vars)
      end
    end

    def send_purchase_confirmation_email_via_hooks(email, template_vars)
      Email::HookCreator::SendTransactionalMail.new(
          client_id: GlobalConstant::TokenSale.st_token_sale_client_id,
          email: email,
          template_name: GlobalConstant::PepoCampaigns.altdrop_sent,
          template_vars: template_vars
      ).perform
    end


    file = File.open(filepath, 'r')

    rows = []

    file.each_line do |line|
      rows << line.strip.split(',')
    end

    file.close

    alt_coin_bonus_logs = AltCoinBonusLog.all.index_by(&:ethereum_address).transform_keys!(&:downcase)

    rows.each_with_index do |row, index|
      user_eth_address = row[0].to_s.downcase
      alt_token_contract_address = row[1].to_s.downcase
      transfer_transaction_hash = row[2].to_s

      puts "#{index} - #{user_eth_address} - #{alt_token_contract_address} - #{transfer_transaction_hash}"

      alt_coin_bonus_log = alt_coin_bonus_logs[user_eth_address]

      fail "alt_token_contract_address did not match" if alt_coin_bonus_log.alt_token_contract_address.downcase != alt_token_contract_address

      next if alt_coin_bonus_log.transfer_transaction_hash.present?

      user_id = Md5UserExtendedDetail.get_user_id(user_eth_address)
      user_email = User.where(id: user_id).first.email

      template_vars = {
          alt_coin_token_name: alt_coin_bonus_log.alt_token_name
      }

      alt_coin_bonus_log.transfer_transaction_hash = transfer_transaction_hash
      alt_coin_bonus_log.save!

      send_alt_coin_bonus_distribution_email(user_email, template_vars)
    end

  end

end

