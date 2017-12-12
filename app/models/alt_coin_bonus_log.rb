class AltCoinBonusLog < EstablishSimpleTokenContractInteractionsDbConnection

  def self.bulk_insert(new_rows)

    logs_sql = "INSERT INTO `alt_coin_bonus_logs` (`ethereum_address`, `alternate_token_id`, `alt_token_name`, `ether_wei_value`, `altcoin_bonus_wei_value`, `created_at`, `updated_at`)" +
        "VALUES #{new_rows.join(', ')} ;"

    self.connection.execute(logs_sql)
  end

end
