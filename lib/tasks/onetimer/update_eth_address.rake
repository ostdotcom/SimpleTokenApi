namespace :onetimer do

  # Update Ethereum Address
  #
  # * Author: Abhay
  # * Date: 10/11/2017
  # * Reviewed By: Kedar
  #
  # rake RAILS_ENV=development onetimer:update_eth_address case_id=2 ethereum_address=0x admin_email=sunil@pepo.com user_email=abhayait@gmail.com
  #
  task :update_eth_address => :environment do

    p " === Starting Updating Ethereum Address ==="

    ActiveRecord::Base.logger = Logger.new(STDOUT)
    r = UserAction::UpdateEthereumAddress.new(
      case_id: ENV['case_id'],
      ethereum_address: ENV['ethereum_address'],
      admin_email: ENV['admin_email'],
      user_email: ENV['user_email']
    ).perform

    p "=== Response ==="
    p r.inspect
    p " === Completed Updating Ethereum Address ==="

  end

end