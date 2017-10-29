namespace :devops do

  # Print all environment variables
  #
  # * Author: Abhay
  # * Date: 27/10/2017
  # * Reviewed By: Sunil
  #
  # rake RAILS_ENV=development devops:echo_env_variables
  #
  task :echo_env_variables => :environment do

    # PP needed to print in new lines
    pp fetch_env_variables

  end

  private

  def fetch_env_variables
    template = ERB.new File.new("#{Rails.root}/config/constants.yml").read
    YAML.load(template.result(binding)).fetch('constants', {}) || {}
  end

end
