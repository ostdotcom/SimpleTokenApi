class ModifyUserKycDetail < DbMigrationConnection

  def up
    run_migration_for_db(EstablishSimpleTokenUserDbConnection.config_key) do
      rename_column :user_kyc_details, :is_re_submitted, :submission_count
      add_column :user_kyc_details, :last_acted_timestamp, :integer, null: true, after: :last_acted_by
    end
  end

  def down
    run_migration_for_db(EstablishSimpleTokenUserDbConnection.config_key) do
      rename_column :user_kyc_details, :submission_count, :is_re_submitted
      remove_column :user_kyc_details, :last_acted_timestamp
    end
  end

end