namespace :onetimer do

  # rake RAILS_ENV=staging onetimer:third_party_erc20_contract_balance

  task :third_party_erc20_contract_balance => :environment do

    @ethereum_addresses = []
    @user_extended_detail_ids = []
    @ethereum_user_mapping = {}
    @failed_other_balance_calls = {}
    @all_users = {}
    @failed_kms_decrypt_ued_ids = []

    @csv_data = []
    @other_ico_balance = {}

    @other_ico_hash = {
        "ST" => "0x2C4e8f2D746113d0696cE89B35F0d8bF88E0AEcA",
        "0x" => "0xe41d2489571d322189246dafa5ebde1f4699f498",
        "AdEx" => "0x4470bb87d77b963a013db939be332f927f2b992e",
        "Aeternity" => "0x5ca9a71b1d01849c0a95490cc00559717fcf0d1d",
        "AirSwap" => "0x27054b13b1b798b345b591a4d22e6562d47ea75a",
        "Aragon" => "0x960b236A07cf122663c4303350609A66A7B288C0",
        "ATMChain" => "0x9B11EFcAAA1890f6eE52C6bB7CF8153aC5d74139",
        "Augur" => "0xe94327d07fc17907b4db788e5adf2ed424addff6",
        "Bancor" => "0x1f573d6fb3f13d689ff844b4ce37794d79a7ff1c",
        "Basic Attention Token" => "0x0d8775f648430679a709e98d2b0cb6250d2887ef",
        "Bitquence" => "0x5af2be193a6abca9c8817001f45744777db30756",
        "ChainLink" => "0x514910771af9ca656af840dff83e8264ecf986ca",
        "Civic" => "0x41e5560054824ea6b0732e656e3ad64e20e94e45",
        "Decentraland" => "0x0f5d2fb29fb7d3cfee444a200298f468908cc942",
        "District0x" => "0x0abdace70d3790235af448c88547603b945604ea",
        "Edgeless" => "0x08711d3b02c8758f2fb3ab4e80228418a7f8e39c",
        "EOS" => "0x86fa049857e0209aa7d9e616f7eb3b3b78ecfdb0",
        "FunFair" => "0x419d0d8bdd9af5e606ae2232ed285aff190e711b",
        "Gnosis" => "0x6810e776880c02933d47db1b9fc05908e5386b96",
        "Golem" => "0xa74476443119A942dE498590Fe1f2454d7D4aC0d",
        "Iconomi" => "0x888666CA69E0f178DED6D75b5726Cee99A87D698",
        "Kin" => "0x818fc6c2ec5986bc6e2cbf00939d90556ab12ce5",
        "Kyber Network" => "0xdd974d5c2e2928dea5f71b9825b8b646686bd200",
        "Loopring" => "0xef68e7c694f40c8202821edf525de3782458639f",
        "MCAP" => "0x93e682107d1e9defb0b5ee701c71707a4b2e46bc",
        "Melon" => "0xBEB9eF514a379B997e0798FDcC901Ee474B6D9A1",
        "Metal" => "0xF433089366899D83a9f26A773D59ec7eCF30355e",
        "Modum" => "0x957c30ab0426e0c93cd8241e2c60392d08c6ac8e",
        "Moeda Loyalty Points" => "0x51db5ad35c671a87207d88fc11d593ac0c8415bd",
        "Monaco" => "0xb63b606ac810a52cca15e44bb630fd42d8d1d83d",
        "OmiseGO" => "0xd26114cd6EE289AccF82350c8d8487fedB8A0C07",
        "Populous" => "0xd4fa1460f537bb9085d22c7bccb5dd450ef28e3a",
        "SALT" => "0x4156D3342D5c385a87D264F90653733592000581",
        "SingularDTV" => "0xaec2e87e0a235266d9c5adc9deb4b2e29b54d009",
        "Status" => "0x744d70fdbe2ba4cf95131626614a1763df805b9e",
        "Storj" => "0xb64ef51c888972c908cfacf59b47c1afbc0ab8ac",
        "TenX" => "0xB97048628DB6B661D4C2aA833e95Dbe1A905B280",
        "TRON" => "0xf230b790e05390fc8295f4d3f60332c93bed42e2",
        "Walton" => "0xb7cb1c96db6b22b0d3d9536e0108d062bd488f74",
        "Wings" => "0x667088b212ce3d06a1b553a7221E1fD19000d9aF"
    }

    def perform

      puts "Starting Script to fetch balance for other contracts"

      fetch_users

      fetch_eth_addresses

      process_contracts

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

    def process_contracts
      @other_ico_hash.each do |ico_name, contract_address|
        puts "fetching balance for: #{ico_name}"
        @other_ico_balance[ico_name.to_s] = fetch_contract_balance(contract_address)
        sleep(2)
      end
    end

    def fetch_contract_balance(contract_address)

      contract_balance = {}

      @ethereum_addresses.each do |ea|
        r = OpsApi::Request::ThirdPartyErc20GetBalance.new.perform({ethereum_address: ea, contract_address: contract_address})
        unless r.success?
          @failed_other_balance_calls[contract_address] ||= []
          @failed_other_balance_calls[contract_address] << ea
          next
        end
        contract_balance[ea] = GlobalConstant::ConversionRate.wei_to_basic_unit_in_string(r.data['balance'].to_i)
        puts "Balance on contract_address:#{contract_address} for ethereum address:#{contract_balance[ea]}"
      end

      contract_balance

    end

    def headers
      header = ['email']
      header.concat(@other_ico_hash.keys)
    end

    def generate_csv_data
      @csv_data << headers.join(',')
      @ethereum_user_mapping.each do |ea, user_id|
        row = [@all_users[user_id].email]
        @other_ico_hash.keys.each do |ico_name|
          row << @other_ico_balance[ico_name.to_s][ea].to_i
        end
        @csv_data << row.join(',')
      end
    end


    def print_as_csv
      @csv_data.each do |row|
        p row
      end
    end

    def create_csv_file
      File.open("other_contract_balance.csv", "w") do |file|
        @csv_data.each do |row|
          file.write(row)
          file.write("\n")
        end
      end
    end

    perform

  end

end