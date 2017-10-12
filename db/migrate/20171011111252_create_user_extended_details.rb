class CreateUserExtendedDetails < DbMigrationConnection

  def up
    run_migration_for_db(EstablishSimpleTokenUserDbConnection.config_key) do

      create_table :user_extended_details do |t|
        t.column :first_name, :string, null: false
        t.column :last_name, :string, null: false
        t.column :kyc_salt, :blob, null: false
        t.column :user_id, :integer, null: false
        t.column :birthdate, :blob, null: false #encrypted
        t.column :street_address, :blob, null: false #encrypted
        t.column :city, :blob, null: false #encrypted
        t.column :state, :blob, null: false #encrypted
        t.column :country, :blob, null: false #encrypted
        t.column :postal_code, :blob, null: false #encrypted
        t.column :ethereum_address, :blob, null: false #encrypted
        t.column :estimated_participation_amount, :blob, null: false #encrypted
        t.column :passport_number, :blob, null: false #encrypted
        t.column :passport_country, :blob, null: false #encrypted
        t.column :passport_url, :string, null: false
        t.column :selfie_url, :string, null: false
        t.timestamps
        t.timestamps
      end

      add_index :user_extended_details, :user_id, unique: false, name: 'uniq_user_id'

    end

  end

  def down
    run_migration_for_db(EstablishSimpleTokenUserDbConnection.config_key) do
      drop_table :user_extended_details
    end
  end

end
