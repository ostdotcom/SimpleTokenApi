namespace :onetimer do

  # Update Ethereum Address
  #
  # * Author: Abhay
  # * Date: 10/11/2017
  # * Reviewed By: Kedar
  #
  # rake RAILS_ENV=development onetimer:update_eth_address case_id=2 ethereum_address=0x admin_email=sunil@pepo.com user_email=abhayait@gmail.com
  #
  # 1) Open the case if it’s closed
  #    rake RAILS_ENV=development onetimer:open_case case_id=6 admin_email=abhay@pepo.com user_email=aman+11@pepo.com
  #
  # 2) rake RAILS_ENV=production onetimer:update_eth_address case_id=0 ethereum_address=0xbd217112d0705451b7dcc7643f875491e041debb admin_email=ignas@pepo.com
  #
  # 3) Copy Log output to file
  #
  # 4) Run code from console to decrypt ethereum address
  #
  # 5) Verify the logs
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