module BonusApproval

  class AltTokenBonusApprovalJob < Base

    # Perform
    #
    # * Author: Aman
    # * Date: 06/11/2017
    # * Reviewed By: Sunil
    #
    def perform(params)
      super
    end

    private

    # start export process
    #
    # * Author: Aman
    # * Date: 06/11/2017
    # * Reviewed By: Sunil
    #
    def start_export_process
      download_file
      process_file
      send_report_mail
    end

    # Process file
    #
    # * Author: Aman
    # * Date: 06/11/2017
    # * Reviewed By: Sunil
    #
    def process_file

      csv_data, emails_last_token_id, count = {}, {}, 0

      CSV.read(@local_file_path).each do |row|
        email = row[0].to_s.strip.downcase
        alt_token_name = row[1].to_s.strip
        alternate_token_id = alternate_tokens[alt_token_name.downcase].try(:id).to_i

        if email.blank? || (alternate_token_id == 0)
          @error_skipped_rows += 1
          next
        end

        csv_data[alternate_token_id] ||= []
        csv_data[alternate_token_id] << email
        count +=1

        emails_last_token_id[email] = alternate_token_id

        if count >= BATCH_SIZE
          check_and_update_user_bonus(csv_data, emails_last_token_id)
          csv_data = {}
          emails_last_token_id = {}
          count = 0
        end
      end

      check_and_update_user_bonus(csv_data, emails_last_token_id) if count > 0
      File.delete(@local_file_path)
    end

    # Get alt token name
    #
    # * Author: Aman
    # * Date: 06/11/2017
    # * Reviewed By: Sunil
    #
    def alternate_tokens
      @alternate_tokens ||= begin
        data = {}
        AlternateToken.where(status: GlobalConstant::AlternateToken.active_status).all.each do |obj|
          data[obj.token_name.downcase] = obj
        end
        data
      end
    end

    # Check and update user bonus
    #
    # * Author: Aman
    # * Date: 06/11/2017
    # * Reviewed By: Sunil
    #
    def check_and_update_user_bonus(csv_data, emails_last_token_id)

      csv_data.each do |alternate_token_id, emails|
        updated_emails = []
        alternate_token_bonus_objs = AlternateTokenBonusEmail.where(email: emails).all.index_by(&:email)

        emails.uniq!

        emails.each do |email|

          alternate_token_obj = alternate_token_bonus_objs[email]

          next if emails_last_token_id[email] != alternate_token_id

          if alternate_token_obj.blank?
            # Always create new entry
            @new_rows += 1
            AlternateTokenBonusEmail.create!(email: email, alternate_token_id: alternate_token_id)
          else
            next if alternate_token_obj.alternate_token_id == alternate_token_id

            @updated_rows += 1
            alternate_token_obj.alternate_token_id = alternate_token_id
            alternate_token_obj.save!
          end

          updated_emails << email
        end

        # Associate bonus with user in kyc details, if required
        user_ids = User.where(client_id: GlobalConstant::TokenSale.st_token_sale_client_id, email: updated_emails).pluck(:id)
        if user_ids.present?
          @kyc_updated_count += UserKycDetail.where(client_id: GlobalConstant::TokenSale.st_token_sale_client_id, user_id: user_ids,
                                                    token_sale_participation_phase: GlobalConstant::TokenSale.early_access_token_sale_phase).
              update_all(alternate_token_id_for_bonus: alternate_token_id, updated_at: Time.zone.now)
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
      'Alternate Token Bonus Export Status'
    end

  end
end
