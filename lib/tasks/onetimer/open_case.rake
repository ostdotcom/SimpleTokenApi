namespace :onetimer do

  # Mark Case as Open
  #
  # * Author: Abhay
  # * Date: 11/11/2017
  # * Reviewed By:
  #
  # rake RAILS_ENV=development onetimer:open_case case_id=2 admin_email='sunil@pepo.com'
  #
  task :open_case => :environment do

    p " === Starting Opening Case Process ==="

    ActiveRecord::Base.logger = Logger.new(STDOUT)
    r = UserAction::OpenCase.new(
      case_id: ENV['case_id'],
      admin_email: ENV['admin_email']
    ).perform

    p "=== Response ==="
    p r.inspect
    p " === Completed Opening Case Process ==="

  end

end