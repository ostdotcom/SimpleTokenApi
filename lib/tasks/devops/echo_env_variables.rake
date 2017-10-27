namespace :devops do

  # Print all environment variables
  #
  # * Author: Abhay
  # * Date: 27/10/2017
  #
  # rake RAILS_ENV=development devops:echo_env_variables
  #
  task :echo_env_variables => :environment do

    env_variables = GlobalConstant::Base.fetch_config
    pp env_variables

  end

end
