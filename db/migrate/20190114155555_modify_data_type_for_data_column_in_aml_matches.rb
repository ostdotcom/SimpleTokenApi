class ModifyDataTypeForDataColumnInAmlMatches < DbMigrationConnection
  def up
    run_migration_for_db(EstablishOstKycAmlDbConnection.config_key) do
      change_column :aml_matches, :data, :binary, :limit => 1.megabyte, :null => false
    end
  end

  def down
    run_migration_for_db(EstablishOstKycAmlDbConnection.config_key) do
      change_column :aml_matcehs, :data, :text, :null => false
    end
  end
end
