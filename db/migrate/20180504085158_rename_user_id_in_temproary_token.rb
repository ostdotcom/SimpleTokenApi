class RenameUserIdInTemproaryToken < DbMigrationConnection

  def up
    run_migration_for_db(EstablishSimpleTokenEmailDbConnection.config_key) do
      rename_column :temporary_tokens, :user_id, :entity_id
    end
  end

  def down
    run_migration_for_db(EstablishSimpleTokenEmailDbConnection.config_key) do
      rename_column :temporary_tokens, :entity_id, :user_id
    end
  end

end
