class RemoveGenderFromUserExtendedDetails < DbMigrationConnection
  def up
    run_migration_for_db(EstablishSimpleTokenUserDbConnection.config_key) do
      remove_column :user_extended_details, :gender
    end
  end
end
