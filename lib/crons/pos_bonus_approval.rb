module Crons

  class PosBonusApproval

    require 'csv'

    def initialize
      @file_name = 'emailpos.csv'
      @local_file_path = "#{Rails.root}/tmp/#{@file_name}"
      @campaign_list_id = GlobalConstant::PepoCampaigns.pos_list_id #2921
    end

    def perform
      download_file
      process_file
    end

    def download_file
      url = Aws::S3Manager.new('kyc', 'admin')
      s_url = url.get_signed_url_for(GlobalConstant::Aws::Common.kyc_bucket, "others/#{@file_name}")
      download_status = system("wget -O #{@local_file_path} '#{s_url}'")
      fail "couldn't download file from #{url}" unless download_status
    end

    def process_file
      batch_size = 100
      selected_emails = {}
      CSV.read(@local_file_path).each do |row|

        selected_emails[row[0]] = row[1]
        if selected_emails.length == batch_size

          check_and_update_user_bonus(selected_emails)
          selected_emails = {}

        end

      end

      check_and_update_user_bonus(selected_emails)

    end

    def check_and_update_user_bonus(selected_emails)

      return if selected_emails.blank?

      pos_bonus_emails = PosBonusEmail.where(email: selected_emails.keys).index_by(&:email)
      user_objs = User.where(email: selected_emails.keys).index_by(&:email)
      user_ids = user_objs.pluck(&:id)
      user_kyc_objs = UserKycDetail.where(user_id: user_ids).index_by(&:user_id)

      selected_emails.each do |email, bonus_in_perc|

        if pos_bonus_emails[email].blank?
          PosBonusEmail.create!(email: email, bonus_percentage: bonus_in_perc)
          Email::Services::PepoCampaigns.new.add_contact(@campaign_list_id, email, {pos_approved: bonus_in_perc})
        end

        u_obj = user_objs[email]
        if u_obj.present? &&
            u_obj.pos_bonus_percentage.blank? &&
            user_kyc_objs[u_obj.id].present? &&
            user_kyc_objs[u_obj.id].token_sale_participation_phase == GlobalConstant::TokenSale.early_access_token_sale_phase

          u_obj.pos_bonus_percentage = bonus_in_perc
          u_obj.save!

        end

      end

    end

  end

end
