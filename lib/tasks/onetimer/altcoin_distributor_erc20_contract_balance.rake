namespace :onetimer do

  # rake RAILS_ENV=staging onetimer:altcoin_distributor_erc20_contract_balance altcoin_distributor_address=0x2C4e8f2D746113d0696cE89B35F0d8bF88E0AEcA

  task :altcoin_distributor_erc20_contract_balance => :environment do

    @altcoin_distributor_address = ENV['altcoin_distributor_address']
    @alt_token_balance = {}

    @failed_other_balance_calls = []

    def perform

      @other_ico_hash = {}

      AlternateToken.all.each do |alt_token|
        @other_ico_hash[alt_token.token_name] = alt_token.contract_address if alt_token.contract_address.present?
      end

      puts "Starting Script to fetch balance for other contracts\n\n"

      fetch_contract_balance

      puts "\n\n\n\n"

      puts "\n\n failed to get balance for address-#{@failed_other_balance_calls}\n\n\n"

      # puts "\n\n balance in wei for altcoins-\t #{@alt_token_balance.inspect}\n\n"

      puts "\n\n balance in st for:: \n\n"
      @alt_token_balance.each do |name, wei_val|
        puts "#{name} - #{GlobalConstant::ConversionRate.wei_to_basic_unit_in_string(wei_val)} - #{wei_val}"
      end

    end

    def fetch_contract_balance
      @other_ico_hash.each do |ico_name, contract_address|
        puts "fetching balance for: #{ico_name}\n"
        r = OpsApi::Request::ThirdPartyErc20GetBalance.new.perform({ethereum_address: @altcoin_distributor_address, contract_address: contract_address})
        unless r.success?
          @failed_other_balance_calls << contract_address
          next
        end
        contract_balance = r.data['balance'].to_i
        puts "Balance on contract_address:#{contract_address} for ethereum address:#{contract_balance}\n"
        @alt_token_balance[ico_name.to_s] = contract_balance
      end
    end

    perform

  end

end