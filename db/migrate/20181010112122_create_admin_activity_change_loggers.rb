class CreateAdminActivityChangeLoggers < DbMigrationConnection

  def up
    run_migration_for_db(EstablishSimpleTokenLogDbConnection.config_key) do
      create_table :admin_activity_change_loggers do |t|
        t.column :client_id, :integer, limit: 8, null: false
        t.column :admin_id, :integer, limit: 8, null: true
        t.column :entity_type, :tinyint, limit: 2, null: false
        t.column :entity_id, :integer, limit: 8, null: false
        t.column :source, :tinyint, limit: 1, null: false
        t.column :column_name, :string, limit: 255, null: false
        t.column :old_val, :string, limit: 500, null: true
        t.column :new_val, :string, limit: 500, null: true
        t.timestamps
      end

    end
  end

  def down
    run_migration_for_db(EstablishSimpleTokenLogDbConnection.config_key) do
      drop_table :admin_activity_change_loggers
    end
  end

end

