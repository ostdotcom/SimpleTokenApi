class ModifyUserExtendedDetail < DbMigrationConnection

  def up
    run_migration_for_db(EstablishSimpleTokenUserDbConnection.config_key) do
      change_column :user_extended_details, :street_address, :blob, null: true
      change_column :user_extended_details, :city, :blob, null: true
      change_column :user_extended_details, :state, :blob, null: true
      change_column :user_extended_details, :postal_code, :blob, null: true
      change_column :user_extended_details, :estimated_participation_amount, :blob, null: true


      change_column :md5_user_extended_details, :street_address, :string, null: true
      change_column :md5_user_extended_details, :city, :string, null: true
      change_column :md5_user_extended_details, :state, :string, null: true
      change_column :md5_user_extended_details, :postal_code, :string, null: true
      change_column :md5_user_extended_details, :estimated_participation_amount, :string, null: true
    end
  end

  def down
    run_migration_for_db(EstablishSimpleTokenUserDbConnection.config_key) do
      change_column :user_extended_details, :street_address, :blob, null: false
      change_column :user_extended_details, :city, :blob, null: false
      change_column :user_extended_details, :state, :blob, null: false
      change_column :user_extended_details, :postal_code, :blob, null: false
      change_column :user_extended_details, :estimated_participation_amount, :blob, null: false


      change_column :md5_user_extended_details, :street_address, :string, null: false
      change_column :md5_user_extended_details, :city, :string, null: false
      change_column :md5_user_extended_details, :state, :string, null: false
      change_column :md5_user_extended_details, :postal_code, :string, null: false
      change_column :md5_user_extended_details, :estimated_participation_amount, :string, null: false
    end
  end

end