class AddIndexToSaleGlobalVariables < DbMigrationConnection

  def up
    run_migration_for_db(EstablishSimpleTokenContractInteractionsDbConnection.config_key) do
      add_index :sale_global_variables, :variable_kind, unique: true, name: 'uniq_variable_kind'
    end
  end

  def down
    run_migration_for_db(EstablishSimpleTokenContractInteractionsDbConnection.config_key) do
      remove_index :sale_global_variables, 'uniq_variable_kind'
    end
  end

end