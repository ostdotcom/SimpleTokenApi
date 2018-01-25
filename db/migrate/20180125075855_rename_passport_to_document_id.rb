class RenamePassportToDocumentId < DbMigrationConnection

  def up

    run_migration_for_db(EstablishSimpleTokenUserDbConnection.config_key) do
      rename_column :user_extended_details, :passport_number, :document_id_number
      rename_column :user_extended_details, :passport_file_path, :document_id_file_path
      rename_column :md5_user_extended_details, :passport_number, :document_id_number
    end

  end

  def down
    run_migration_for_db(EstablishSimpleTokenUserDbConnection.config_key) do
      rename_column :user_extended_details, :document_id_number, :passport_number
      rename_column :user_extended_details, :document_id_file_path, :passport_file_path
      rename_column :md5_user_extended_details, :document_id_number, :passport_number
    end
  end

end
