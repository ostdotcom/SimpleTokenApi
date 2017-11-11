namespace :onetimer do

  # Mark Case as Open
  #
  # * Author: Abhay
  # * Date: 11/11/2017
  # * Reviewed By:
  #
  # rake RAILS_ENV=development onetimer:open_case case_id=6 admin_email=abhay@pepo.com user_email=aman+11@pepo.com
  #
  task :open_case => :environment do

    p " === Starting Opening Case Process ==="

    ActiveRecord::Base.logger = Logger.new(STDOUT)
    r = UserAction::OpenCase.new(
      case_id: ENV['case_id'],
      admin_email: ENV['admin_email'],
      user_email: ENV['user_email']
    ).perform

    p "=== Response ==="
    p r.inspect
    p " === Completed Opening Case Process ==="

  end

end