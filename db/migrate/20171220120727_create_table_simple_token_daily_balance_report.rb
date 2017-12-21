class CreateTableSimpleTokenDailyBalanceReport < DbMigrationConnection

  def up
    run_migration_for_db(EstablishSimpleTokenLogDbConnection.config_key) do
      create_table :simple_token_daily_balance_reports do |t|
        t.column :ethereum_address, :string, limit: 255, null: false
        t.column :iteration_count, :integer, null: false, default: 0
        t.column :st_wei_value, :decimal, precision: 30, scale: 0, null: false
        t.column :st_value, :decimal, precision: 20, scale: 10, null: false
        t.column :day, :integer, null: false, default: 0, limit: 4
        t.column :month, :integer, null: false, default: 0, limit: 4
        t.column :year, :integer, limit: 1, null: false, limit: 4
        t.column :execution_timestamp, :integer, null: false
        t.timestamps
      end


      add_index :simple_token_daily_balance_reports, [:ethereum_address], unique: false, name: 'ethereum_address_index'
      add_index :simple_token_daily_balance_reports, [:iteration_count], unique: false, name: 'iteration_count_index'
    end
  end

  def down
    run_migration_for_db(EstablishSimpleTokenLogDbConnection.config_key) do
      drop_table :simple_token_daily_balance_reports
    end
  end

end

