class AddInvestorDetailsInUserExtendedDetails < DbMigrationConnection
  def up
    run_migration_for_db(EstablishSimpleTokenUserDbConnection.config_key) do
      add_column :user_extended_details, :investor_proof_files_path, :blob, null: true, after: :residence_proof_file_path #encrypted
    end
  end

  def down
    run_migration_for_db(EstablishSimpleTokenUserDbConnection.config_key) do
      remove_column :user_extended_details, :investor_proof_files_path
    end
  end
end
