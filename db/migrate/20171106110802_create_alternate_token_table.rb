class CreateAlternateTokenTable < DbMigrationConnection

  def up
    run_migration_for_db(EstablishSimpleTokenLogDbConnection.config_key) do
      create_table :alternate_tokens do |t|
        t.column :token_name, :string, null: false, limit: 60
        t.column :status, :tinyint, null: false, limit: 4
        t.timestamps
      end

      create_table :alternate_token_bonus_emails do |t|
        t.column :email, :string, limit: 255, null: false
        t.column :alternate_token_id, :integer, limit: 8, null: false
        t.timestamps
      end

      add_index :alternate_tokens, [:token_name], unique: true, name: 'TOKEN_NAME_UNIQUE_INDEX'
      add_index :alternate_token_bonus_emails, [:email], unique: true, name: 'EMAIL_UNIQUE_INDEX'

    end
  end

  def down
    run_migration_for_db(EstablishSimpleTokenLogDbConnection.config_key) do
      drop_table :alternate_tokens
      drop_table :alternate_token_bonus_emails
    end
  end

end