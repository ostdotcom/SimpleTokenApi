class CreateTokenSaleDoubleOptInTokens < DbMigrationConnection

  def up
    run_migration_for_db(EstablishSimpleTokenEmailDbConnection.config_key) do
      create_table :token_sale_double_opt_in_tokens do |t|
        t.column :user_id, :integer, null: false
        t.column :token, :string, null: false
        t.column :status, :integer, limit: 4, default: 1
        t.timestamps
      end
      add_index :token_sale_double_opt_in_tokens, :user_id, unique: true, name: 'uniq_user_id'
    end
  end

  def down
    run_migration_for_db(EstablishSimpleTokenEmailDbConnection.config_key) do
      drop_table :token_sale_double_opt_in_tokens if EstablishSimpleTokenEmailDbConnection.exists? :token_sale_double_opt_in_tokens
    end
  end

end
