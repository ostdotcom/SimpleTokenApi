class ModifySaleGlobalVariable < DbMigrationConnection

  def up
    run_migration_for_db(EstablishSimpleTokenContractInteractionsDbConnection.config_key) do
      change_column :sale_global_variables, :variable_data, :string, limit: 100, null: false
    end
  end

  def down
    run_migration_for_db(EstablishSimpleTokenContractInteractionsDbConnection.config_key) do
      change_column :sale_global_variables, :variable_data, :integer, null: false
    end
  end
end
