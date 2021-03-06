namespace :cron_task do

  namespace :continuous do

    DEFAULT_RUNNING_INTERVAL = 1.hour

    # sample code for one to user a continuous running cron
    # Steps :
    # 1. set @process_name which would make the lock file name
    # 2. set @DEFAULT_RUNNING_INTERVAL, time for which we want to run one contininuos instance. If blank we default to DEFAULT_RUNNING_INTERVAL
    # 3. set @optional_params, if we want to pass them to initialize of performer_klass
    # 4. set @performer_klass with the name of a klass which
    #     its initializer should accept a hash key because cronjob will pass cronjob id to it
    #     and other optinal params
    #     Example: Search::Hooks::Processor.new()
    #     and implements perform method
    # 5. call execute_task method

    # Process Email Service API Call hooks
    #
    # * Author: Puneet
    # * Date: 10/10/2017
    # * Reviewed By: Sunil
    #
    desc "rake RAILS_ENV=development cron_task:continuous:process_email_service_api_call_hooks lock_key_suffix=1"
    desc "*/1 * * * * cd /mnt/simpletoken-api/current && rake RAILS_ENV=staging cron_task:continuous:process_email_service_api_call_hooks lock_key_suffix=1 >> /mnt/simpletoken-api/shared/log/process_email_service_api_call_hooks.log"
    task :process_email_service_api_call_hooks do |task|
      @sleep_interval = 2

      @process_name = "#{task}_#{ENV['lock_key_suffix']}"
      @performer_klass = 'Crons::HookProcessors::EmailServiceApiCall'
      @optional_params = {}
      execute_continuous_task
    end

    # Process User KYC Whitelist Call hooks
    #
    # * Author: Aman
    # * Date: 25/10/2017
    # * Reviewed By: Sunil
    #
    desc "rake RAILS_ENV=development cron_task:continuous:process_kyc_whitelist_call_hooks shard_identifiers=shard_1,shard_2"
    desc "*/5 * * * * cd /mnt/simpletoken-api/current && rake RAILS_ENV=staging cron_task:continuous:process_kyc_whitelist_call_hooks shard_identifiers=shard_1,shard_2 >> /mnt/simpletoken-api/shared/log/process_kyc_whitelist_call_hooks.log"
    task :process_kyc_whitelist_call_hooks do |task|
      @sleep_interval = 10

      shard_identifiers = ENV['shard_identifiers'].to_s.split(',').map(&:to_i)


      @process_name = "#{task}_#{ENV['lock_key_suffix'].to_i}"
      @performer_klass = 'Crons::KycWhitelistProcessor'
      @optional_params = {shard_identifiers: shard_identifiers}
      execute_continuous_task
    end


    # Process User Submitted Images Call hooks
    #
    # * Author: Tejas
    # * Date: 12/07/2018
    # * Reviewed By:
    #
    desc "rake RAILS_ENV=development cron_task:continuous:process_user_submitted_images_call_hooks cron_identifier=p1 shard_identifiers=shard_1,shard_2"
    desc "*/1 * * * * cd /mnt/simpletoken-api/current && rake RAILS_ENV=staging cron_task:continuous:process_user_submitted_images_call_hooks cron_identifier=p1 shard_identifiers=shard_1,shard_2 >> /mnt/simpletoken-api/shared/log/process_user_submitted_images_call_hooks.log"
    task :process_user_submitted_images_call_hooks do |task|
      @sleep_interval = 1

      shard_identifiers = ENV['shard_identifiers'].to_s.split(',').map(&:to_i)

      cron_identifier = ENV['cron_identifier'].to_s
      @process_name = "#{task}_#{cron_identifier}"
      @performer_klass = 'Crons::ProcessUserSubmittedImages'
      @optional_params = {cron_identifier: cron_identifier, shard_identifiers: shard_identifiers}
      execute_continuous_task
    end


    # Process User KYC Whitelist Call hooks
    #
    # * Author: Aman
    # * Date: 26/10/2017
    # * Reviewed By: Kedar
    #
    desc "rake RAILS_ENV=development cron_task:continuous:confirm_kyc_whitelist"
    desc "*/5 * * * * cd /mnt/simpletoken-api/current && rake RAILS_ENV=staging cron_task:continuous:confirm_kyc_whitelist >> /mnt/simpletoken-api/shared/log/confirm_kyc_whitelist.log"
    task :confirm_kyc_whitelist do |task|
      @sleep_interval = 60

      @process_name = "#{task}_#{ENV['lock_key_suffix'].to_i}"
      @performer_klass = 'Crons::ConfirmKycWhitelist'
      @optional_params = {}
      execute_continuous_task
    end

    # Process webhooks
    #
    # * Author: Aman
    # * Date: 15/10/2018
    # * Reviewed By:
    #
    desc "rake RAILS_ENV=development cron_task:continuous:process_webhooks"
    desc "*/5 * * * * cd /mnt/simpletoken-api/current && rake RAILS_ENV=staging cron_task:continuous:process_webhooks cron_identifier=p1 >> /mnt/simpletoken-api/shared/log/process_webhooks.log"
    task :process_webhooks do |task|
      @sleep_interval = 1
      cron_identifier = ENV['cron_identifier'].to_s

      @process_name = "#{task}_#{cron_identifier}"
      @performer_klass = 'Crons::Webhooks::Send'
      @optional_params = {cron_identifier: cron_identifier}
      execute_continuous_task
    end

    # Read and process blocks on ether net
    #
    # * Author: Aman
    # * Date: 06/11/2017
    # * Reviewed By:
    #
    desc "rake RAILS_ENV=development cron_task:continuous:read_blocks_on_ethernet"
    desc "*/5 * * * * cd /mnt/simpletoken-api/current && rake RAILS_ENV=staging cron_task:continuous:read_blocks_on_ethernet >> /mnt/simpletoken-api/shared/log/read_blocks_on_ethernet.log"
    task :read_blocks_on_ethernet do |task|
      @sleep_interval = 15

      @process_name = "#{task}_#{ENV['lock_key_suffix'].to_i}"
      @performer_klass = 'Crons::ReadBlockEvents'
      @optional_params = {}
      execute_continuous_task
    end

    # Process User Aml Search
    #
    # * Author: Tejas
    # * Date: 10/01/2018
    # * Reviewed By:
    #
    desc "rake RAILS_ENV=development cron_task:continuous:process_user_aml_search cron_identifier=p1 shard_identifiers=shard_1,shard_2"
    desc "*/1 * * * * cd /mnt/simpletoken-api/current && rake RAILS_ENV=staging cron_task:continuous:process_user_aml_search cron_identifier=p1 shard_identifiers=shard_1,shard_2 >> /mnt/simpletoken-api/shared/log/process_user_aml_search.log"
    task :process_user_aml_search do |task|
      @sleep_interval = 1

      shard_identifiers = ENV['shard_identifiers'].to_s.split(',').map(&:to_i)

      cron_identifier = ENV['cron_identifier'].to_s
      @process_name = "#{task}_#{cron_identifier}"
      @performer_klass = 'Crons::AmlProcessors::Search'
      @optional_params = {cron_identifier: cron_identifier, shard_identifiers: shard_identifiers}
      execute_continuous_task
    end

    private

    # task which running a continuing instance of perform method in performer klass
    # also define the chain of tasks that need to run with every continuous cron
    #
    # * Author: Puneet
    # * Date: 10/10/2017
    # * Reviewed By: Sunil
    #
    task :execute_task => [:validate_params, :acquire_lock, :set_up_environment] do

      begin

        @iteration_count = 1
        @running_interval ||= DEFAULT_RUNNING_INTERVAL
        @sleep_interval ||= 10 # In Seconds

        register_signal_handlers

        while (!GlobalConstant::SignalHandling.sigint_received?) && (@start_time + @running_interval) > Time.now do

          current_time = Time.now
          log_line "Starting iteration #{@iteration_count} at #{current_time} with params: #{@params}"

          performer_klass = @performer_klass.constantize.new(@params)
          performer_klass.perform

          @iteration_count += 1
          sleep(@sleep_interval) unless GlobalConstant::SignalHandling.sigint_received? # sleep for @sleep_interval second after one iteration.
        end
      rescue Exception => e

        ApplicationMailer.notify(
            body: {exception: {message: e.message, backtrace: e.backtrace}},
            data: {},
            subject: "Exception in cron_task:continuous:#{@process_name}"
        ).deliver

        log_line("Exception : <br/> #{CGI::escapeHTML(e.inspect)}<br/><br/><br/>Backtrace:<br/>#{CGI::escapeHTML(e.backtrace.inspect)}")

      ensure
        log_line("Ended at => #{Time.now} after #{@iteration_count} iterations")
      end
    end

    # hepler methods

    # output logged lines
    #
    # * Author: Puneet
    # * Date: 10/10/2017
    # * Reviewed By: Sunil
    #
    def log_line(line)
      puts "cron_task:continuous:#{@process_name} : #{line}"
    end

    # Start the cron job
    # Called once. This internally sleeps for some time between processing multiple batches
    #
    # * Author: Puneet
    # * Date: 10/10/2017
    # * Reviewed By: Sunil
    #
    def execute_continuous_task
      Rake::Task['cron_task:continuous:execute_task'].reenable
      Rake::Task['cron_task:continuous:execute_task'].invoke
      @lock_file_handle.close
    end

  end

end
