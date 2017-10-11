class CreateUserExtendedDetails < DbMigrationConnection

  def up
    run_migration_for_db(EstablishSimpleTokenUserDbConnection.config_key) do

      create_table :user_extended_details do |t|
        t.column :user_id, :integer, null: false
        t.column :birthdate, :string, null: false
        t.column :street_address, :string, null: false
        t.column :city, :string, null: false
        t.column :state, :string, null: false
        t.column :country, :string, null: false
        t.column :postal_code, :string, null: false
        t.column :ethereum_address, :string, null: false
        t.column :estimated_participation_amount, :string, null: false
        t.column :passport_number, :string, null: false
        t.column :passport_url, :string, null: false
        t.column :selfie_url, :string, null: false
        t.timestamps
        t.timestamps
      end

      add_index :user_extended_details, :user_id, unique: true, name: 'user_uid'

    end

  end

  def down
    run_migration_for_db(EstablishSimpleTokenUserDbConnection.config_key) do
      drop_table :user_extended_details
    end
  end

end
