class SimpleTokenDailyBalanceReport < EstablishSimpleTokenLogDbConnection


  def self.bulk_insert(new_rows)

    logs_sql = "INSERT INTO `simple_token_daily_balance_reports` (`ethereum_address`, `iteration_count`, `st_wei_value`, `st_value`, `day`, `month`, `year`, `execution_timestamp`, `created_at`, `updated_at`)" +
        "VALUES #{new_rows.join(', ')} ;"

    self.connection.execute(logs_sql)
  end

end