class PosBonusApprovalJob < ApplicationJob

  queue_as GlobalConstant::Sidekiq.queue_name :default_medium_priority_queue

  require 'csv'

  # Perform
  #
  # * Author: Aman
  # * Date: 29/10/2017
  # * Reviewed By: Sunil
  #
  def perform(params)

    init_params(params)

    start_export_process

  end

  private

  # initialize
  #
  # * Author: Alpesh
  # * Date: 27/10/2017
  # * Reviewed By: Sunil
  #
  # @return [PosBonusApprovalJob]
  #
  def init_params(params)
    @file_name = params[:pos_file_name]
    @local_file_path = "#{Rails.root}/tmp/#{@file_name}"

    @new_rows, @updated_rows, @error_skipped_rows, @kyc_updated_count = 0, 0, 0, 0
  end

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

  # Download file
  #
  # * Author: Alpesh
  # * Date: 27/10/2017
  # * Reviewed By: Sunil
  #
  def download_file
    url = Aws::S3Manager.new('kyc', 'admin')
    s_url = url.get_signed_url_for(GlobalConstant::Aws::Common.external_data_bucket, "#{Rails.env}/proof-of-support/#{@file_name}")
    download_status = system("wget -O #{@local_file_path} '#{s_url}'")
    fail "couldn't download file from #{url}" unless download_status
  end

  # Process file
  #
  # * Author: Alpesh
  # * Date: 27/10/2017
  # * Reviewed By: Sunil
  #
  def process_file
    batch_size = 100

    csv_data, count = {}, 0
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

      if count >= batch_size
        check_and_update_user_bonus(csv_data)
        csv_data = {}
        count = 0
      end
    end

    check_and_update_user_bonus(csv_data) if count > 0
    File.delete(@local_file_path)
  end

  # Check and update user bonus
  #
  # * Author: Alpesh
  # * Date: 27/10/2017
  # * Reviewed By: Sunil
  #
  def check_and_update_user_bonus(csv_data)

    csv_data.each do |bonus_percentage, emails|
      updated_emails = []
      pos_bonus_objs = PosBonusEmail.where(email: emails).all.index_by(&:email)

      emails.each do |email|
        pos_obj = pos_bonus_objs[email]

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
      user_ids = User.where(email: updated_emails).pluck(:id)
      if user_ids.present?
        @kyc_updated_count += UserKycDetail.where(user_id: user_ids, token_sale_participation_phase: GlobalConstant::TokenSale.early_access_token_sale_phase).
            update_all(pos_bonus_percentage: bonus_percentage, updated_at: Time.zone.now)
        UserKycDetail.bulk_flush(user_ids)
      end
    end

  end

  # Send report to admin
  #
  # * Author: Alpesh
  # * Date: 27/10/2017
  # * Reviewed By: Sunil
  #
  def send_report_mail
    send_to = Rails.env.production? ? GlobalConstant::Email.default_pm_to : GlobalConstant::Email.default_to
    ApplicationMailer.notify(
        to: send_to,
        body: {},
        data: {
            error_skipped_rows: @error_skipped_rows,
            new_rows: @new_rows,
            updated_rows: @updated_rows,
            kyc_updated_count: @kyc_updated_count
        },
        subject: 'Proof Of Support Export Status'
    ).deliver
  end

end

