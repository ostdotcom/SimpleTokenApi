class ModifyEditKycTables < DbMigrationConnection

  def self.up
    run_migration_for_db(EstablishSimpleTokenLogDbConnection.config_key) do
      add_column :edit_kyc_requests, :update_action, :tinyint, :null => false, :default => 0, :after => :open_case_only
    end
  end

  def self.down
    run_migration_for_db(EstablishSimpleTokenLogDbConnection.config_key) do
      remove_column :edit_kyc_requests, :update_action
    end
  end

end
