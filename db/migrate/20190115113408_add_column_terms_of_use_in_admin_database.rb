class AddColumnTermsOfUseInAdminDatabase < DbMigrationConnection
  def up
    run_migration_for_db(EstablishSimpleTokenAdminDbConnection.config_key) do
      add_column :admins, :terms_of_use, :tinyint, :limit => 1,  after: :status, null: false, default: GlobalConstant::Admin.accepted_terms_of_use
    end
  end

  def down
    run_migration_for_db(EstablishSimpleTokenAdminDbConnection.config_key) do
      remove_column :admins, :terms_of_use
    end
  end
end
