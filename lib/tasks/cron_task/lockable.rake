namespace :cron_task do

  namespace :lockable do

    # sample code for one to user a continuous running cron
    # Steps :
    # 1. set @process_name which would make the lock file name
    # 2. set @optional_params, if we want to pass them to initialize of performer_klass
    # 3. set @performer_klass with the name of a klass which
    #     its initializer should accept a hash key because cronjob will pass cronjob id to it
    #     and other optinal params
    #     Example: Search::Hooks::Processor.new()
    #
    #     and implements perform method which takes current timestamp as an input ex : performer.perform(current_time.to_i)
    # 4. call execute_task method
    #

    # Retry email service api hook jobs for failed entries
    #
    # * Author: Puneet
    # * Date: 10/10/2017
    # * Reviewed By: Kedar
    #
    desc "rake RAILS_ENV=development cron_task:lockable:retry_email_service_api_call_hooks"
    desc "*/5 * * * * cd /mnt/simpletoken-api/current && rake RAILS_ENV=development cron_task:lockable:retry_email_service_api_call_hooks >> /mnt/simpletoken-api/shared/log/retry_email_service_api_call_hooks.log"
    task :retry_email_service_api_call_hooks do |task|
      @process_name = task
      @performer_klass = 'Crons::HookProcessors::EmailServiceApiCall'
      @optional_params = {process_failed: true}
      execute_lockable_task
    end

    # Check Eth balance of whitelister
    #
    # * Author: Aman
    # * Date: 06/11/2017
    # * Reviewed By:
    #
    desc "rake RAILS_ENV=development cron_task:lockable:check_eth_balance_of_whitelister"
    desc "*/30 * * * * cd /mnt/simpletoken-api/current && rake RAILS_ENV=development cron_task:lockable:check_eth_balance_of_whitelister >> /mnt/simpletoken-api/shared/log/check_eth_balance_of_whitelister.log"
    task :check_eth_balance_of_whitelister do |task|
      @process_name = task
      @performer_klass = 'Crons::CheckWhitelisterBalance'
      @optional_params = {}
      execute_lockable_task
    end

    # Populate Client usage of api and notify kyc team after a threshold
    #
    # * Author: Aman
    # * Date: 18/09/2017
    # * Reviewed By:
    #
    desc "rake RAILS_ENV=development cron_task:lockable:populate_client_usage"
    desc "*/30 * * * * cd /mnt/simpletoken-api/current && rake RAILS_ENV=development cron_task:lockable:populate_client_usage >> /mnt/simpletoken-api/shared/log/populate_client_usage.log"
    task :populate_client_usage do |task|
      @process_name = task
      @performer_klass = 'Crons::PopulateClientUsage'
      @optional_params = {}
      execute_lockable_task
    end

    # Refresh gas price
    #
    # * Author: Pankaj
    # * Date: 18/09/2018
    # * Reviewed By:
    #
    desc "rake RAILS_ENV=development cron_task:lockable:refresh_dynamic_gas_price"
    desc "*/5 * * * * cd /mnt/simpletoken-api/current && rake RAILS_ENV=development cron_task:lockable:refresh_dynamic_gas_price >> /mnt/simpletoken-api/shared/log/refresh_dynamic_gas_price.log"
    task :refresh_dynamic_gas_price do |task|
      @process_name = task
      @performer_klass = 'Crons::RefreshTransactionGasPrice'
      @optional_params = {}
      execute_lockable_task
    end

    # Delte MFA Logs
    #
    # * Author: Aman
    # * Date: 13/04/2019
    # * Reviewed By:
    #
    desc "rake RAILS_ENV=development cron_task:lockable:delete_mfa_logs"
    desc "* */6 * * * cd /mnt/simpletoken-api/current && rake RAILS_ENV=development cron_task:lockable:delete_mfa_logs >> /mnt/simpletoken-api/shared/log/delete_mfa_logs.log"
    task :delete_mfa_logs do |task|
      @process_name = task
      @performer_klass = 'Crons::DeleteMfaLogs'
      @optional_params = {}
      execute_lockable_task
    end

    private

    # task which running a continuing instance of perform method in performer klass
    # also define the chain of tasks that need to run with every continuous cron
    #
    # * Author: Puneet
    # * Date: 10/10/2017
    # * Reviewed By:
    #
    task :execute_task => [:validate_params, :acquire_lock, :set_up_environment] do

      begin

        register_signal_handlers
        current_time = Time.now
        log_line "Starting at #{current_time} with params: #{@params}"
        performer_klass = @performer_klass.constantize.new(@params)
        performer_klass.perform

      rescue Exception => e

        ApplicationMailer.notify(
            body: {exception: {message: e.message, backtrace: e.backtrace}},
            data: {},
            subject: "Exception in cron_task:lockable:#{@process_name}"
        ).deliver

        log_line("Exception : <br/> #{CGI::escapeHTML(e.inspect)}<br/><br/><br/>Backtrace:<br/>#{CGI::escapeHTML(e.backtrace.inspect)}")

      ensure
        log_line("Ended at => #{Time.now} ")
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
      puts "cron_task:lockable:#{@process_name} : #{line}"
    end

    # Start the cron job and also make it available to be executed for next time in same iteration
    #
    # * Author: Puneet
    # * Date: 10/10/2017
    # * Reviewed By: Sunil
    #
    def execute_lockable_task
      Rake::Task['cron_task:lockable:execute_task'].reenable
      Rake::Task['cron_task:lockable:execute_task'].invoke
      @lock_file_handle.close
    end

  end

end
