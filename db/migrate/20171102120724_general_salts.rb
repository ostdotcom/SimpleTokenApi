class GeneralSalts < DbMigrationConnection

  def up
    run_migration_for_db(EstablishSimpleTokenApiDbConnection.config_key) do
      create_table :general_salts do |t|
        t.column :salt_type, :tinyint, null: false, limit: 4
        t.column :salt, :blob, null: false
        t.timestamps
      end

      add_index :general_salts, [:salt_type], unique: true, name: 'SALT_TYPE_UNIQUE_INDEX'
    end

  end

  def down
    run_migration_for_db(EstablishSimpleTokenApiDbConnection.config_key) do
      drop_table :general_salts
    end
  end

end
