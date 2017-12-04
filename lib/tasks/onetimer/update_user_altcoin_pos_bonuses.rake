namespace :onetimer do

  # rake onetimer:update_user_altcoin_pos_bonuses RAILS_ENV=development

  task :update_user_altcoin_pos_bonuses => :environment do

    user_emails, altcoin_users, pos_users = {}, {}, {}

    alternate_tokens = {}
    AlternateToken.where(status: GlobalConstant::AlternateToken.active_status).all.each do |obj|
      alternate_tokens[obj.token_name.downcase] = obj
    end

    file = File.open("alt_pos_final_choice.csv", "r")

    file.each_with_index do |row, index|
      next if index == 0
      arr = row.gsub("\r", "").gsub("\n", "").split(",")
      email = arr[0]
      choice = arr[1]

      user_id = User.where(email: email).first.id

      fail "User not found for #{email}" if user_id <= 0

      user_emails[email] = user_id

      if choice.to_i > 0
        pos_users[user_id] = choice.to_i
      else
        alternate_token_id = alternate_tokens[alt_token_name.downcase].try(:id).to_i
        fail "Alt token not found for #{email}" if alternate_token_id <= 0
        altcoin_users[user_id] = alternate_token_id
      end
    end

    user_emails.each do |email, user_id|
      # If user has selected pos bonus
      if pos_users[user_id].present?
        bonus = pos_users[user_id].to_i
        UserKycDetail.where(user_id: user_id).update_all(alternate_token_id_for_bonus: nil, pos_bonus_percentage: bonus)
        AlternateTokenBonusEmail.where(email: email).delete
        pos_bonus = PosBonusEmail.where(email: email).first
        if pos_bonus.blank?
          pos_bonus = PosBonusEmail.new
          pos_bonus.email = email
        end
        pos_bonus.bonus_percentage = bonus
        pos_bonus.save
      elsif altcoin_users[user_id].present?
        # If user has selected altcoin bonus
        alternate_token_id = altcoin_users[user_id]
        UserKycDetail.where(user_id: user_id).update_all(alternate_token_id_for_bonus: alternate_token_id, pos_bonus_percentage: nil)
        PosBonusEmail.where(email: email).delete
        alt_bonus_email = AlternateTokenBonusEmail.where(email: email).first
        if alt_bonus_email.blank?
          alt_bonus_email = AlternateTokenBonusEmail.new
          alt_bonus_email.email = email
        end
        alt_bonus_email.alternate_token_id = alternate_token_id
        alt_bonus_email.save
      end
    end
    UserKycDetail.bulk_flush(user_emails.values)

  end

end
