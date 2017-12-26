class ModifyAdmins < DbMigrationConnection

  def up
    run_migration_for_db(EstablishSimpleTokenAdminDbConnection.config_key) do
      add_column :admins, :default_client_id, :integer, null: true, after: :name
    end
  end

  def down
    run_migration_for_db(EstablishSimpleTokenAdminDbConnection.config_key) do
      remove_column :admins, :default_client_id
    end
  end

end