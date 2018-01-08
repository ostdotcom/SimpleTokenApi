namespace :onetimer do

  # Update Ethereum Address For Bonus Allocations
  #
  # * Author: Puneet
  # * Date: 08/01/2018
  # * Reviewed By:
  #
  # rake RAILS_ENV=development onetimer:update_eth_address_for_bonus_distribution
  #
  task :update_eth_address_for_bonus_distribution => :environment do

    include Util::ResultHelper

    require 'csv'

    def read_from_csv

      CSV.foreach("#{Rails.root}/lib/tasks/onetimer/update_eth_address_for_bonus_distribution.csv", :headers => true) do |row|

        # parse & Validate CSV row
        parsed_data = parse_csv_row(row)
        validation_rsp = is_valid_csv_row?(parsed_data)
        if validation_rsp.success?
          @valid_rows[parsed_data[:email]] = parsed_data
        else
          puts "validation error row found: #{row} : #{validation_rsp.to_json}"
          @invalid_rows << {
              row: row,
              error: validation_rsp.to_json
          }
          next
        end

      end

    end

    def fetch_existing_eth_address

      emails = @valid_rows.keys

      user_id_email_map, ukd_ids = {}, []

      User.where(email: emails).select(:id, :email).each do |user|
        @valid_rows[user.email][:user_id] = user.id
        user_id_email_map[user.id] = user.email
      end

      UserKycDetail.where(user_id: user_id_email_map.keys).
          select(:user_id, :user_extended_detail_id).each do |ukd|
        ukd_ids << ukd.user_extended_detail_id
        @valid_rows[user_id_email_map[ukd.user_id]][:user_extended_detail_id_id] = ukd.user_extended_detail_id
      end

      UserExtendedDetail.where(id: ukd_ids).
          select(:id, :user_id, :ethereum_address, :kyc_salt).each do |ued|

        kyc_salt_e = ued.kyc_salt
        decrypt_key_rsp = Aws::Kms.new('kyc', 'admin').decrypt(kyc_salt_e)
        unless decrypt_key_rsp.success?
          @invalid_rows << {
              user_id: ued.user_id,
              error: decrypt_key_rsp.to_json
          }
          next
        end

        local_cipher_obj = LocalCipher.new(decrypt_key_rsp.data[:plaintext])
        decrypt_key_rsp = local_cipher_obj.decrypt(ued.ethereum_address)
        if decrypt_key_rsp.success?
          @valid_rows[user_id_email_map[ued.user_id]][:old_eth_address] = decrypt_key_rsp.data[:plaintext]
        else
          @invalid_rows << {
              user_id: ued.user_id,
              error: decrypt_key_rsp.to_json
          }
          next
        end

      end

    end

    def fetch_bonus_logs

      @valid_rows.each do |email, email_data|
        buffer = BonusTokenLog.where(ethereum_address: email_data[:old_eth_address]).first
        if buffer.blank?
          @invalid_rows << {
              email: email,
              error: 'no row in bonus logs'
          }
          next
        else
          email_data[:bonus_log] = buffer
        end
      end

    end

    # Sr. No	Ticket No	Date Recvd	Email	Name	Doc ID - KYC	KYC Check	New Ethereum Add
    def parse_csv_row(csv_row)
      {
          s_no: csv_row['Sr. No'],
          ticket_no: csv_row['Ticket No'],
          email: csv_row['Email'],
          name: csv_row['Name'],
          new_eth_address: csv_row['New Ethereum Add']
      }
    end

    def is_valid_csv_row?(parsed_data)
      unless parsed_data[:email].present? && parsed_data[:ticket_no].present? && parsed_data[:name].present?
        return error_rsp('uea_1', 'Mandatory param missing')
      end
      is_valid_eth_address?(parsed_data[:new_eth_address])
    end

    def is_valid_eth_address?(eth_address)
      return error_rsp('uea_1', 'ETH Address Missing') if eth_address.blank?
      UserManagement::CheckEthereumAddress.new(ethereum_address: eth_address).perform
    end

    def error_rsp(err_code, display_text)
      error_with_data(
          err_code,
          display_text,
          display_text,
          GlobalConstant::ErrorAction.default,
          {}
      )
    end

    def process_csv_data(data)
      bonus_log = data[:bonus_log]
      # bonus_log.update_attributes!(ethereum_address_for_bonus_distribution: data[:new_eth_address])
      puts "would update #{bonus_log.id} to address #{data[:new_eth_address]} debug data : #{data}"
      success
    end

    def perform

      p " === Starting Updating Ethereum Address For Bonus Distribution ==="

      ActiveRecord::Base.logger = Logger.new(STDOUT)

      @invalid_rows = []
      @valid_rows = {}

      read_from_csv
      if @invalid_rows.present?
        puts "Validation Error Rows"
        puts @invalid_rows
        return
      end

      fetch_existing_eth_address
      if @invalid_rows.present?
        puts "ETH Address Validation Error Rows"
        puts @invalid_rows
        return
      end

      fetch_bonus_logs
      if @invalid_rows.present?
        puts "Bonus Logs Validation Error Rows"
        puts @invalid_rows
        return
      end

      @valid_rows.each do |email, data|
        process_rsp = process_csv_data(data)
        unless process_rsp.success?
          puts "processing error row found: #{row} : #{process_rsp.to_json}"
          @invalid_rows << {
              row: row,
              error: process_rsp.to_json
          }
          next
        end
      end

      if @invalid_rows.present?
        puts "Processing Error Rows"
        puts @invalid_rows
        return
      end

    end

    perform

  end

end