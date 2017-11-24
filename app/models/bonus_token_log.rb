class BonusTokenLog < EstablishSimpleTokenContractInteractionsDbConnection

  enum is_pre_sale: {
           GlobalConstant::BonusTokenLog.true_is_pre_sale => 1,
           GlobalConstant::BonusTokenLog.false_is_pre_sale => 2
       }, _suffix: true


  def self.bulk_insert(new_rows)

    logs_sql = "INSERT INTO `bonus_token_logs` (`ethereum_address`, `st_wei_value`, `st_total_bonus_wei_value`, `pos_bonus`, `community_bonus_percent`,`eth_adjustment_bonus`, `is_pre_sale`, `st_pre_sale_bonus_wei_value`, `created_at`, `updated_at`)" +
        "VALUES #{new_rows.join(', ')} ;"

    self.connection.execute(logs_sql)
  end

end

