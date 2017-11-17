namespace :onetimer do

  # rake RAILS_ENV=staging onetimer:third_party_erc20_contract_balance

  task :fetch_white_listed_users_ethereum_addresses => :environment do

    @ethereum_addresses = []
    @ethereum_user_mapping = {}
    @all_users = {}

    @csv_data = []

    def perform

      fetch_users

      fetch_eth_addresses

      generate_csv_data

      print_as_csv

      create_csv_file

      puts "\n\n\n\n"

    end

    def fetch_users
      user_ids = []
      UserKycDetail.where(whitelist_status: GlobalConstant::UserKycDetail.done_whitelist_status).each do |u_k_d|
        @user_extended_detail_ids << u_k_d.user_extended_detail_id
        user_ids << u_k_d.user_id
      end

      @all_users = User.select("id, email").where(:id => user_ids).index_by(&:id)

    end


    def fetch_eth_addresses
      UserExtendedDetail.where(:id => @user_extended_detail_ids).each do |user_extended_detail|

        r = Aws::Kms.new('kyc', 'admin').decrypt(user_extended_detail.kyc_salt)
        unless r.success?
          @failed_kms_decrypt_ued_ids << user_extended_detail.id
          next
        end

        kyc_salt_d = r.data[:plaintext]

        decryptor_obj = LocalCipher.new(kyc_salt_d)

        ea = decryptor_obj.decrypt(user_extended_detail.ethereum_address).data[:plaintext]

        @ethereum_user_mapping[ea] = user_extended_detail.user_id

        @ethereum_addresses << ea

      end

      @ethereum_addresses.uniq!

    end

    def generate_csv_data
      @ethereum_user_mapping.each do |ea, user_id|
        @csv_data << "#{@all_users[user_id].email}, #{ea}"
      end
    end


    def print_as_csv
      @csv_data.each do |row|
        p row
      end
    end

    def create_csv_file
      File.open("white_listed_ethereum_addresses.csv", "w") do |file|
        @csv_data.each do |row|
          file.write(row)
          file.write("\n")
        end
      end
    end

    perform

  end

end