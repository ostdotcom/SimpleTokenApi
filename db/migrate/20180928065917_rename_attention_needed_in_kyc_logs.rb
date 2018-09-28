class RenameAttentionNeededInKycLogs < DbMigrationConnection
  def up
    run_migration_for_db(EstablishSimpleTokenContractInteractionsDbConnection.config_key) do
      rename_column :kyc_whitelist_logs, :is_attention_needed, :failed_reason
    end
  end

  def down
    run_migration_for_db(EstablishSimpleTokenContractInteractionsDbConnection.config_key) do
      rename_column :kyc_whitelist_logs, :failed_reason, :is_attention_needed
    end
  end
end
