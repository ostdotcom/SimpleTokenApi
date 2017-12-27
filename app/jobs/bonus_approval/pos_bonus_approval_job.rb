module BonusApproval
  class PosBonusApprovalJob < Base

    # Perform
    #
    # * Author: Aman
    # * Date: 29/10/2017
    # * Reviewed By: Sunil
    #
    def perform(params)
      super
    end

    private

    # start_export_process
    #
    # * Author: Aman
    # * Date: 29/10/2017
    # * Reviewed By: Sunil
    #
    def start_export_process
      download_file
      process_file
      send_report_mail
    end

    # Process file
    #
    # * Author: Alpesh
    # * Date: 27/10/2017
    # * Reviewed By: Sunil
    #
    def process_file

      csv_data, count = {}, 0
      emails_max_bonus_percent = {}
      CSV.read(@local_file_path).each do |row|
        email = row[0].to_s.strip.downcase
        bonus_percentage = row[1].to_s.strip.to_f

        if email.blank? || [0, 10].exclude?(bonus_percentage)
          @error_skipped_rows += 1
          next
        end

        csv_data[bonus_percentage] ||= []
        csv_data[bonus_percentage] << email
        count +=1

        emails_max_bonus_percent[email] = bonus_percentage if emails_max_bonus_percent[email].to_i <= bonus_percentage

        if count >= BATCH_SIZE
          check_and_update_user_bonus(csv_data, emails_max_bonus_percent)
          csv_data = {}
          emails_max_bonus_percent = {}
          count = 0
        end
      end

      check_and_update_user_bonus(csv_data, emails_max_bonus_percent) if count > 0
      File.delete(@local_file_path)
    end

    # Check and update POS user bonus
    #
    # * Author: Alpesh
    # * Date: 27/10/2017
    # * Reviewed By: Sunil
    #
    def check_and_update_user_bonus(csv_data, emails_max_bonus_percent)

      csv_data.each do |bonus_percentage, emails|
        updated_emails = []
        pos_bonus_objs = PosBonusEmail.where(email: emails).all.index_by(&:email)

        emails.uniq!

        emails.each do |email|
          pos_obj = pos_bonus_objs[email]

          next if emails_max_bonus_percent[email] != bonus_percentage

          if pos_obj.blank?
            # Always create new entry
            @new_rows += 1
            PosBonusEmail.create!(email: email, bonus_percentage: bonus_percentage)
          else
            # Only update if bonus percent in table is 0 (means: rejected POS is now approved by admin)
            # Else don't do anything automatically. Handle other cases manually
            next if pos_obj.bonus_percentage > 0

            @updated_rows += 1
            pos_obj.bonus_percentage = bonus_percentage
            pos_obj.save!
          end

          updated_emails << email
        end

        # Associate bonus with user in kyc details, if required
        user_ids = User.where(client_id: GlobalConstant::TokenSale.st_token_sale_client_id, email: updated_emails).pluck(:id)
        if user_ids.present?
          @kyc_updated_count += UserKycDetail.where(client_id: GlobalConstant::TokenSale.st_token_sale_client_id, user_id: user_ids, token_sale_participation_phase: GlobalConstant::TokenSale.early_access_token_sale_phase).
              update_all(pos_bonus_percentage: bonus_percentage, updated_at: Time.zone.now)
          UserKycDetail.bulk_flush(user_ids)
        end
      end

    end

    # Report email subject
    #
    # * Author: Aman
    # * Date: 06/11/2017
    # * Reviewed By: Sunil
    #
    def report_mail_subject
      'Proof Of Support Export Status'
    end

  end
end

