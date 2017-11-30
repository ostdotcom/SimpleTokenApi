namespace :onetimer do

  # rake onetimer:unmark_altcoin_bonus RAILS_ENV=development

  task :unmark_altcoin_bonus => :environment do

    pos_qualified_user_ids = []
    records = PurchaseLog.connection.execute(
        'select ethereum_address, sum(ether_wei_value) as ether_in_wei from purchase_logs where block_creation_timestamp <= 1510750793 group by ethereum_address;')

    records.each do |record|

      if record[1] >= 1000000000000000000
        qualified_user_ids << Md5UserExtendedDetail.get_user_id(record[0])
      else
        pos_qualified_user_ids << Md5UserExtendedDetail.get_user_id(record[0])
      end
    end

    unmark_alt_bonus_user_ids = UserKycDetail.where('user_id not in (?)', qualified_user_ids).
        where("alternate_token_id_for_bonus > 0").pluck(:user_id)


    mark_for_pos_user_ids = unmark_alt_bonus_user_ids  & pos_qualified_user_ids
    UserKycDetail.where(user_id: mark_for_pos_user_ids).update_all(pos_bonus_percentage: 10)

    UserKycDetail.where(user_id: unmark_alt_bonus_user_ids).update_all(alternate_token_id_for_bonus: nil)
    UserKycDetail.bulk_flush(unmark_alt_bonus_user_ids)

    emails = User.where('id not in ?', qualified_user_ids).pluck(:email)

    unmark_emails = AlternateTokenBonusEmail.where(email: emails).pluck(:email)
    unmark_emails.each do |email|
      puts "#{email}"
    end

    AlternateTokenBonusEmail.where(email: emails).delete_all

    #check
    puts UserKycDetail.where(user_id: (qualified_user_ids + pos_qualified_user_ids)).where('(pos_bonus_percentage = 0 or pos_bonus_percentage is null)and (alternate_token_id_for_bonus = 0 or alternate_token_id_for_bonus is null) ').count
  end

end
