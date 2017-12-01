class PreSalePurchaseLog < EstablishSimpleTokenContractInteractionsDbConnection

  def self.bulk_insert(new_rows)

    logs_sql = "INSERT INTO `pre_sale_purchase_logs` (`ethereum_address`, `st_base_token`, `st_bonus_token`, `eth_adjustment_bonus_percent`, `is_ingested_in_trustee`, `created_at`, `updated_at`)" +
        "VALUES #{new_rows.join(', ')} ;"

    self.connection.execute(logs_sql)
  end

end

