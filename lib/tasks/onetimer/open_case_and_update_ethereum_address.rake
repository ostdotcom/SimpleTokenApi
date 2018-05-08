# namespace :onetimer do
#
#   # Mark Case as Open
#   #
#   # * Author: Abhay
#   # * Date: 11/11/2017
#   # * Reviewed By: Sunil
#   #
#   # rake RAILS_ENV=development onetimer:open_case_and_update_ethereum_address case_id=6 ethereum_address=0x admin_email=abhay@pepo.com user_email=aman+11@pepo.com open_case_only=0
#   #
#   task :open_case_and_update_ethereum_address => :environment do
#
#     p " === Starting Opening Case and Updating Ethereum Address Process ==="
#
#     ActiveRecord::Base.logger = Logger.new(STDOUT)
#
#     r = UserAction::OpenCaseAndUpdateEthereumAddress.new(
#       case_id: ENV['case_id'],
#       admin_email: ENV['admin_email'],
#       user_email: ENV['user_email'],
#       ethereum_address: ENV['ethereum_address'],
#       open_case_only: ENV['open_case_only']
#     ).perform
#
#     p "=== Response ==="
#     p r.inspect
#     p " === Completed Opening Case and Updating Ethereum Address Process ==="
#
#   end
#
# end