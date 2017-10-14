class CreateUserKycDetails < DbMigrationConnection

  def up

    run_migration_for_db(EstablishSimpleTokenUserDbConnection.config_key) do
      create_table :user_kyc_details do |t|
        t.column :user_id, :integer, limit: 8, null: false
        t.column :user_extended_detail_id, :integer, limit: 8, null: false
        t.column :cynopsis_user_id, :string, null: true
        t.column :kyc_confirmed_at, :integer, limit: 8, null: false
        t.column :token_sale_participation_phase, :integer, limit: 4, null: false
        t.column :is_re_submitted, :integer, limit: 4, null: false
        t.column :is_duplicate, :integer, limit: 4, null: false
        t.column :cynopsis_status, :integer, limit: 4, null: false
        t.column :admin_status, :integer, limit: 4, null: false
        t.column :last_acted_by, :integer, limit: 8, null: true
        t.timestamps
      end
      #TODO - add indexes according to queries of filters.
      add_index :user_kyc_details, :user_id, unique: true, name: 'uniq_user_id'
    end

  end

  def down
    run_migration_for_db(EstablishSimpleTokenUserDbConnection.config_key) do
      drop_table :user_kyc_details
    end
  end

end
