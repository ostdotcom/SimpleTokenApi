class CreateTemporaryTokens < DbMigrationConnection

  def up
    run_migration_for_db(EstablishSimpleTokenEmailDbConnection.config_key) do
      create_table :temporary_tokens do |t|
        t.column :user_id, :integer, null: false
        t.column :token, :string, null: false
        t.column :kind, :integer, limit: 4, null: false
        t.column :status, :integer, limit: 4, default: 1, null: false
        t.timestamps
      end
      add_index :temporary_tokens, [:user_id, :kind, :status], unique: false, name: 'user_id_kind_status'
    end
  end

  def down
    run_migration_for_db(EstablishSimpleTokenEmailDbConnection.config_key) do
      drop_table :temporary_tokens if EstablishSimpleTokenEmailDbConnection.exists? :temporary_tokens
    end
  end

end
