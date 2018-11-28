class AddVersionIdForClientWhitelistDetail < DbMigrationConnection
  def up
    run_migration_for_db(EstablishSimpleTokenClientDbConnection.config_key) do
      add_column :client_whitelist_details, :version_id, :string, limit: 100, after: :last_acted_by, :null => true
    end

    run_migration_for_db(EstablishSimpleTokenContractInteractionsDbConnection.config_key) do
      add_column :kyc_whitelist_logs, :client_whitelist_detail_version_id, :string, limit: 100, after: :client_whitelist_detail_id, :null => true
    end

    #  migrate current rows
    ClientWhitelistDetail.all.each do |cwd|
      cwd.version_id = Utility.generate_random_id
      cwd.source = GlobalConstant::AdminActivityChangeLogger.script_source
      cwd.save!

      KycWhitelistLog.where(client_whitelist_detail_id: cwd.id).
          update_all(client_whitelist_detail_version_id: cwd.version_id)
    end

    run_migration_for_db(EstablishSimpleTokenClientDbConnection.config_key) do
      change_column :client_whitelist_details, :version_id, :string, limit: 100, :null => false
    end


    run_migration_for_db(EstablishSimpleTokenContractInteractionsDbConnection.config_key) do
      remove_column :kyc_whitelist_logs, :client_whitelist_detail_id
    end

    Rails.cache.clear

  end

  def down
    run_migration_for_db(EstablishSimpleTokenClientDbConnection.config_key) do
      remove_column :client_whitelist_details, :version_id
    end

    run_migration_for_db(EstablishSimpleTokenContractInteractionsDbConnection.config_key) do
      remove_column :kyc_whitelist_logs, :client_whitelist_detail_version_id
    end
  end


end