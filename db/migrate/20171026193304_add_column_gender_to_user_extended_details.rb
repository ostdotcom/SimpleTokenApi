class AddColumnGenderToUserExtendedDetails < DbMigrationConnection

  def up
    run_migration_for_db(EstablishSimpleTokenUserDbConnection.config_key) do
      add_column :user_extended_details, :gender, :tinyint, limit: 1, null: false, defaut: 0, after: :last_name
    end
  end

  def down
    run_migration_for_db(EstablishSimpleTokenUserDbConnection.config_key) do
      remove_column :user_extended_details, :gender
    end
  end

end
