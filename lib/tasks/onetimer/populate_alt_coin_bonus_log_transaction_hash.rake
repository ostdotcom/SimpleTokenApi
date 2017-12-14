namespace :onetimer do

  # rake RAILS_ENV=staging onetimer:populate_alt_coin_bonus_log_transaction_hash

  task :populate_alt_coin_bonus_log_transaction_hash => :environment do

    filepath = "#{Rails.root}/lib/tasks/onetimer/alt_coin_bonus_log_transaction_hash_data.csv"

    def send_alt_coin_bonus_distribution_email(email, template_vars)
      send_mail_response = Email::Services::PepoCampaigns.new.send_transactional_email(
          email, GlobalConstant::PepoCampaigns.alt_coin_bonus_distribution, template_vars)

      if send_mail_response['error'].present?
        puts "error in send email without hook response- #{send_mail_response.inspect}"
        send_purchase_confirmation_email_via_hooks(email, template_vars)
      end
    end

    def send_purchase_confirmation_email_via_hooks(email, template_vars)
      Email::HookCreator::SendTransactionalMail.new(
          email: email,
          template_name: GlobalConstant::PepoCampaigns.alt_coin_bonus_distribution,
          template_vars: template_vars
      ).perform
    end


    file = File.open(filepath, 'r')

    rows = file.first.split("\r")

    file.close

    alt_coin_bonus_logs = AltCoinBonusLog.all.index_by(&:ethereum_address).transform_keys!(&:downcase)

    rows.each_with_index do |row, index|
      arr = row.split(",")
      user_eth_address = arr[0].to_s.downcase
      alt_token_contract_address = arr[1].to_s.downcase
      transfer_transaction_hash = arr[2].to_s

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

    # File.delete(filepath)
  end

end

