class CreateTermsAcceptedLogs < DbMigrationConnection
  def up
    run_migration_for_db(EstablishSimpleTokenAdminDbConnection.config_key) do

      create_table :terms_accepted_logs do |t|
        t.column :admin_id, :integer, limit: 8, null: false
        t.column :terms_version, :string, limit: 10, null: false
        t.timestamps
      end

    end
  end

  def down
    run_migration_for_db(EstablishSimpleTokenAdminDbConnection.config_key) do
      drop_table :terms_accepted_logs
    end
  end
end

