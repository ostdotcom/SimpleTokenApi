namespace :onetimer do

  # rake onetimer:populate_st_balance_for_processable_users RAILS_ENV=development

  task :populate_st_balance_for_processable_users => :environment do

    @token_balance_data = []
    @report_csv_data = []

    @last_iteration_count = SimpleTokenDailyBalanceReport.maximum(:iteration_count).to_i
    @current_iteration_count = @last_iteration_count + 1
    @execution_time = Time.now


    def fetch_processables_distribution_data
      @processable_addresses_data = ProcessableDistribution.select('ethereum_address, sum(st_value) as total_st_distributed').
          group(:ethereum_address).all.index_by(&:ethereum_address).transform_keys!(&:downcase)
    end

    def fetch_contract_balance(ethereum_address)
      puts "fetching balance for: #{ethereum_address}\n"
      r = OpsApi::Request::ThirdPartyErc20GetBalance.new.perform({ethereum_address: ethereum_address, contract_address: GlobalConstant::TokenSale.simple_token_contract_address})
      fail "unable to fetch contract balance for address- #{ethereum_address}" unless r.success?
      balance_in_wei = r.data['balance'].to_i
      balance_in_wei
    end

    def fetch_st_balances
      @processable_addresses_data.each do |ethereum_address, data|
        balance_in_wei = fetch_contract_balance(ethereum_address)
        balance_in_basic_unit = GlobalConstant::ConversionRate.wei_to_basic_unit_in_string(balance_in_wei).to_f.round(2)
        @token_balance_data << [ethereum_address, balance_in_wei, balance_in_basic_unit]
      end
    end

    def insert_in_table
      day = @execution_time.day
      month = @execution_time.month
      year = @execution_time.year
      current_time = @execution_time.to_s(:db)
      sql_data = []

      @token_balance_data.each do |rows|
        sql_data << "('#{rows[0]}', #{@current_iteration_count}, #{rows[1]}, #{rows[2]}, #{day}, #{month}, #{year}, #{@execution_time.to_i}, '#{current_time}', '#{current_time}')"
      end

      SimpleTokenDailyBalanceReport.bulk_insert(sql_data)
    end

    def create_csv_report_data
      last_day_max_count = SimpleTokenDailyBalanceReport.where('execution_timestamp < ? ', @execution_time.beginning_of_day.to_i).
          maximum(:iteration_count).to_i

      previous_balances_rows = SimpleTokenDailyBalanceReport.where(iteration_count: last_day_max_count).all.
          index_by(&:ethereum_address).transform_keys!(&:downcase)

      @report_csv_data << ['ethereum_address', 'total_st_distributed', 'current_balance', 'previous_balance', 'total_st_movement', 'last_run_time_diff_in_hours']

      @token_balance_data.each do |rows|
        previous_balance, st_difference, time_difference_in_hours = nil, nil, nil

        ethereum_address = rows[0]
        st_in_basic_unit = rows[2]

        total_st_distributed = @processable_addresses_data[ethereum_address].total_st_distributed.to_i
        previous_balance_obj = previous_balances_rows[ethereum_address.downcase]

        if previous_balance_obj.present?
          previous_balance = previous_balance_obj.st_value
          st_difference = st_in_basic_unit - previous_balance
          time_difference_in_hours = ((@execution_time.to_i - previous_balance_obj.execution_timestamp)/3600.0).floor
        end

        @report_csv_data << [ethereum_address, total_st_distributed, st_in_basic_unit, previous_balance, st_difference, time_difference_in_hours]
      end

    end

    def upload_to_s3_and_email
      local_filepath = "#{Rails.root}/lib/tasks/onetimer/daily_st_balance_report.csv"
      s3_path = "daily_st_data/report_#{@execution_time.to_s(:db).gsub(' ', '_')}.csv"

      File.open(local_filepath, 'w') do |f|
        @report_csv_data.each do |row|
          f.puts row.join(",")
        end
      end

      s3_manager_obj = Aws::S3Manager.new('kyc', 'admin')

      s3_manager_obj.store(
          s3_path,
          File.open(local_filepath),
          GlobalConstant::Aws::Common.report_bucket,
          {
              content_type: 'application/vnd.ms-excel'
          }
      )

      File.delete(local_filepath)

      s3_url = s3_manager_obj.get_signed_url_for(
          GlobalConstant::Aws::Common.report_bucket,
          s3_path,
          {
              expires_in: 12.hours.to_i
          }
      )

      ApplicationMailer.notify(
          to: Rails.env.production? ? GlobalConstant::Email.st_balance_report_email_to : 'aman@pepo.com',
          body: "url for report- #{s3_url}",
          subject: 'Daily Processables ST Balance Report'
      ).deliver

    end

    def perform
      fetch_processables_distribution_data
      fetch_st_balances
      insert_in_table
      create_csv_report_data
      upload_to_s3_and_email
    end

    perform

  end

end