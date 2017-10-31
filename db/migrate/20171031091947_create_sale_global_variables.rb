class CreateSaleGlobalVariables < DbMigrationConnection

  def up
    run_migration_for_db(EstablishSimpleTokenContractInteractionsDbConnection.config_key) do
      create_table :sale_global_variables do |t|
        t.column :variable_kind, :tinyint, null: false, limit: 4
        t.column :variable_data, :integer, null: false
        t.timestamps
      end

      execute "INSERT INTO sale_global_variables (variable_kind, variable_data, created_at, updated_at) VALUES
            ('#{SaleGlobalVariable.variable_kinds[GlobalConstant::SaleGlobalVariable.sale_ended_variable_kind]}', 0, '#{Time.now.to_s(:db)}', '#{Time.now.to_s(:db)}'),
            ('#{SaleGlobalVariable.variable_kinds[GlobalConstant::SaleGlobalVariable.last_block_processed_variable_kind]}', 0, '#{Time.now.to_s(:db)}', '#{Time.now.to_s(:db)}');"

    end

  end

  def down
    run_migration_for_db(EstablishSimpleTokenContractInteractionsDbConnection.config_key) do
      drop_table :sale_global_variables
    end
  end

end
