namespace :onetimer do

  # rake onetimer:mark_pos_of_early_access_purchasers RAILS_ENV=development

  task :mark_pos_of_early_access_purchasers => :environment do

    user_ids = []
    last_time = 1510750793

    PurchaseLog.where("block_creation_timestamp <= ?", last_time).all.pluck(:ethereum_address).uniq.each do |ethereum_address|

      user_ids << Md5UserExtendedDetail.get_user_id(ethereum_address)

    end

    bonus_percentage = 10
    user_emails = {}
    updated_emails = []
    failed_user_ids = []

    User.where(id: user_ids).select("id, email").each do |usr|
      user_emails[usr.id] = usr.email
    end

    UserKycDetail.where(user_id: user_ids).each do |u_k_c|
      if u_k_c.token_sale_participation_phase != GlobalConstant::TokenSale.early_access_token_sale_phase
        failed_user_ids << u_k_c.user_id
        next
      end
      next if u_k_c.pos_bonus_percentage.to_i > 0
      next if u_k_c.alternate_token_id_for_bonus.to_i > 0

      u_k_c.pos_bonus_percentage = bonus_percentage
      u_k_c.save!

      updated_emails << user_emails[u_k_c.user_id].email

    end

    UserKycDetail.bulk_flush(user_ids)

    puts "-updated_emails-----------------------------------------------------------------------"
    puts "\n\n#{updated_emails.inspect}\n\n"

    puts "-failed_user_ids-----------------------------------------------------------------------"
    puts "\n\n#{failed_user_ids.inspect}\n\n"
    puts "------------------------------------------------------------------------"

  end

end
