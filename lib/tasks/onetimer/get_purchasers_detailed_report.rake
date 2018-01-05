namespace :onetimer do

  # rake onetimer:get_purchasers_detailed_report RAILS_ENV=development

  task :get_purchasers_detailed_report => :environment do

    def get_decoded_info(u_e_d)
      r = Aws::Kms.new('kyc', 'admin').decrypt(u_e_d.kyc_salt)
      unless r.success?
        @failed_kms_decrypt_ued_ids << u_e_d.id
        return ""
      end
      kyc_salt_d = r.data[:plaintext]

      decryptor_obj = LocalCipher.new(kyc_salt_d)

      birth_date = decryptor_obj.decrypt(u_e_d.birthdate).data[:plaintext]

      age = ((Time.now.to_i - birth_date.to_time.to_i) / 1.year.to_f)

      {
        country: decryptor_obj.decrypt(u_e_d.country).data[:plaintext],
        city: decryptor_obj.decrypt(u_e_d.city).data[:plaintext],
        age: age
      }
    end

    early_access_last_time = 1510750793

    transaction_details = []
    ether_to_user_mapping = {}

    PurchaseLog.order("block_creation_timestamp ASC").all.each do |pl|
      ethereum_address = pl.ethereum_address
      bought_in_early_access, bought_in_public_sale = false, false
      if pl.block_creation_timestamp <= early_access_last_time
        bought_in_early_access = true
      else
        bought_in_public_sale = true
      end

      transaction_details << {
        ethereum_address: ethereum_address,
        bought_in_early_access: bought_in_early_access,
        bought_in_public_sale: bought_in_public_sale,
        ether_wei_value: pl.ether_wei_value,
        purchase_time: Time.at(pl.block_creation_timestamp).in_time_zone('Pacific Time (US & Canada)').strftime("%d/%m/%Y %H:%M:%S")
      }

      ether_to_user_mapping[ethereum_address] ||= Md5UserExtendedDetail.get_user_id(GlobalConstant::TokenSale.st_token_sale_client_id, ethereum_address)
    end

    user_ids = ether_to_user_mapping.values
    users = User.where(id: user_ids).all.index_by(&:id)
    user_kyc_details = UserKycDetail.where(user_id: user_ids).all.index_by(&:user_id)
    utm_details = UserUtmLog.where(user_id: user_ids).all.index_by(&:user_id)
    alternate_tokens = AlternateToken.all.index_by(&:id)
    user_extended_detail_ids = []
    user_kyc_details.each do |_, u_k_d|
      user_extended_detail_ids << u_k_d.user_extended_detail_id
    end

    user_extended_details = UserExtendedDetail.where(:id => user_extended_detail_ids).index_by(&:id)

    csv_data = []
    csv_data << [
      'email',
      'country',
      'city',
      'age',
      'register_datetime',
      'purchase_time',
      'bought_in_early_access',
      'bought_in_public_sale',
      'alt_token_name',
      'pos_bonus',
      'purchased_amount_in_eth',
      'utm_source',
      'utm_medium',
      'utm_campaign'
    ]

    transaction_details.each do |transaction_data|

      user_id = ether_to_user_mapping[transaction_data[:ethereum_address]]
      user = users[user_id]
      user_kyc_detail = user_kyc_details[user_id]
      utm_detail = utm_details[user_id]
      alt_token_name = alternate_tokens[user_kyc_detail.alternate_token_id_for_bonus.to_i].try(:token_name)
      decoded_info = get_decoded_info(user_extended_details[user_kyc_detail.user_extended_detail_id])

      purchased_amount_in_eth = (transaction_data[:ether_wei_value] * 1.0 /GlobalConstant::ConversionRate.ether_to_wei_conversion_rate).round(4)

      data = [
        user.email,
        decoded_info[:country],
        decoded_info[:city],
        decoded_info[:age],
        user.created_at.in_time_zone('Pacific Time (US & Canada)').strftime("%d/%m/%Y %H:%M:%S"),
        transaction_data[:purchase_time],
        transaction_data[:bought_in_early_access],
        transaction_data[:bought_in_public_sale],
        alt_token_name,
        user_kyc_detail.pos_bonus_percentage.to_i,
        purchased_amount_in_eth,
        utm_detail.try(:utm_source),
        utm_detail.try(:utm_medium),
        utm_detail.try(:utm_campaign)
      ]
      csv_data << data
    end

    puts "----------------------\n\n\n"

    csv_data.each do |element|
      puts element.join(',')
    end

    puts "-----------------------\n\n\n"

  end

end
