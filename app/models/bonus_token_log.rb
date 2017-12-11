class BonusTokenLog < EstablishSimpleTokenContractInteractionsDbConnection

  enum is_pre_sale: {
           GlobalConstant::BonusTokenLog.true_is_pre_sale => 1,
           GlobalConstant::BonusTokenLog.false_is_pre_sale => 2
       }, _suffix: true

  enum is_ingested_in_trustee: {
            GlobalConstant::BonusTokenLog.true_is_ingested_in_trustee => 1,
            GlobalConstant::BonusTokenLog.false_is_ingested_in_trustee => 2
        }, _suffix: true


  def self.bulk_insert(new_rows)

    logs_sql = "INSERT INTO `bonus_token_logs` (`ethereum_address`, `purchase_in_st_wei`, `purchase_in_st`, `total_bonus_in_wei`, `total_bonus_value_in_st`, `pos_bonus_percent`, `pos_bonus_in_st`, `community_bonus_percent`, `community_bonus_in_st`, `discretionary_bonus_percent`, `discretionary_bonus_in_st`, `is_pre_sale`, `is_ingested_in_trustee`, `pre_sale_bonus_in_st`, `created_at`, `updated_at`)" +
        "VALUES #{new_rows.join(', ')} ;"

    self.connection.execute(logs_sql)
  end

end

