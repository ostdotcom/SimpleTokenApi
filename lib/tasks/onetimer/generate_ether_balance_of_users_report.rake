namespace :onetimer do

  # rake RAILS_ENV=development onetimer:generate_ether_balance_of_users_report

  task :generate_ether_balance_of_users_report => :environment do

    fetch_data

  end

  # fetch data and print it on console
  #
  # * Author: Aman
  # * Date: 16/11/2017
  # * Reviewed By:
  #
  #
  def fetch_data

    csv_data = []
    csv_data << ['email', 'purchased_amount', 'eth_value']

    all_ued_ids = UserKycDetail.kyc_admin_and_cynopsis_approved.pluck(:user_extended_detail_id)

    all_ued_ids.each_slice(100) do |ued_ids|
      UserExtendedDetail.where(id: ued_ids).all.each do |user_extended_detail|
        r = Aws::Kms.new('kyc', 'admin').decrypt(user_extended_detail.kyc_salt)
        next unless r.success?
        kyc_salt_d = r.data[:plaintext]
        data = generate_case_data(kyc_salt_d, user_extended_detail)
        csv_data << data if data[:eth_value] >= 10.0
      end
      sleep(1)
    end

    puts "----------------------\n\n\n"
    csv_data.each do |element|
      puts element.values.join(',')
    end
    puts "-----------------------\n\n\n"

  end

  # generate case data
  #
  # * Author: Aman
  # * Date: 15/11/2017
  # * Reviewed By:
  #
  # @return [Hash]
  #
  def generate_case_data(kyc_salt_d, user_extended_detail)
    decryptor_obj = LocalCipher.new(kyc_salt_d)
    ethereum_address = decryptor_obj.decrypt(user_extended_detail.ethereum_address).data[:plaintext]

    total_st_wei_value = 0
    eth_value_in_wei = 0
    PurchaseLog.where(ethereum_address: ethereum_address).each do |pl|
      total_st_wei_value += pl.st_wei_value
    end

    user = User.where(id: user_extended_detail.user_id).first

    r = OpsApi::Request::GetEthBalance.new.perform(ethereum_address: ethereum_address)
    fail "error from ops api - #{r.inspect}" unless r.success?
    eth_value_in_wei = r.data['balance']

    eth_value = (eth_value_in_wei.to_i/GlobalConstant::ConversionRate.ether_to_wei_conversion_rate).round(2)
    purchased_amount = (total_st_wei_value/GlobalConstant::ConversionRate.ether_to_wei_conversion_rate).round(2)

    {
        email: user.email,
        purchased_amount: purchased_amount,
        eth_value: eth_value
    }
  end

end