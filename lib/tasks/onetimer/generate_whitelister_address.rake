namespace :onetimer do

  # Generate Whitelister Address and insert it into verified_operator_address Table
  #
  # * Author: Tejas
  # * Date: 05/10/2018
  # * Reviewed By:
  #
  # rake RAILS_ENV=development onetimer:generate_whitelister_address
  #
  task :generate_whitelister_address => :environment do

    50.times do
      r = Request::OpsApi::GenerateWhitelisterAddress.new.perform({})
      fail "Unable to get whitelister address" unless r.success?
      whitelister_address = r.data['whitelisterAddress']
      VerifiedOperatorAddress.create!(address: whitelister_address,
                                      status: GlobalConstant::VerifiedOperatorAddress.unused_status)
    end
  end

end