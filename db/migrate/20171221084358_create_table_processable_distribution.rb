class CreateTableProcessableDistribution < DbMigrationConnection

  def up
    run_migration_for_db(EstablishSimpleTokenLogDbConnection.config_key) do
      create_table :processable_distributions do |t|
        t.column :ethereum_address, :string, limit: 255, null: false
        t.column :st_wei_value, :decimal, precision: 30, scale: 0, null: false
        t.column :st_value, :decimal, precision: 20, scale: 10, null: false
        t.column :month, :integer, null: true, default: 0, limit: 4
        t.column :year, :integer, limit: 1, null: true, limit: 4
        t.timestamps
      end


      add_index :processable_distributions, [:ethereum_address], unique: false, name: 'ethereum_address_index'
      add_index :processable_distributions, [:month, :year], unique: false, name: 'month_year_index'
    end
  end

  def down
    run_migration_for_db(EstablishSimpleTokenLogDbConnection.config_key) do
      drop_table :processable_distributions
    end
  end

end
