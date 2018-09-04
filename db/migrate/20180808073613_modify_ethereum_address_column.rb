class ModifyEthereumAddressColumn < DbMigrationConnection

  def up
    run_migration_for_db(EstablishSimpleTokenUserDbConnection.config_key) do
      change_column :user_extended_details, :ethereum_address, :blob, null: true

      change_column :md5_user_extended_details, :ethereum_address, :string, null: true
    end
  end

  def down
    run_migration_for_db(EstablishSimpleTokenUserDbConnection.config_key) do
      change_column :user_extended_details, :ethereum_address, :blob, null: false

      change_column :md5_user_extended_details, :ethereum_address, :string, null: false
    end
  end

end
