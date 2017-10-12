class CreateMd5UserExtendedDetails < DbMigrationConnection

  def up
    run_migration_for_db(EstablishSimpleTokenUserDbConnection.config_key) do

      create_table :md5_user_extended_details do |t|
        t.column :user_id, :integer, limit: 8, null: false
        t.column :user_extended_detail_id, :integer, limit: 8, null: false
        t.column :first_name, :string, null: true
        t.column :last_name, :string, null: true
        t.column :kyc_salt, :blob, null: true
        t.column :birthdate, :string, null: false
        t.column :street_address, :string, null: false
        t.column :city, :string, null: false
        t.column :state, :string, null: false
        t.column :country, :string, null: false
        t.column :postal_code, :string, null: false
        t.column :ethereum_address, :string, null: false
        t.column :estimated_participation_amount, :string, null: false
        t.column :passport_number, :string, null: false
        t.column :passport_country, :string, null: false
        t.timestamps
        t.timestamps
      end

    end

  end

  def down
    run_migration_for_db(EstablishSimpleTokenUserDbConnection.config_key) do
      drop_table :md5_user_extended_details
    end
  end

end
