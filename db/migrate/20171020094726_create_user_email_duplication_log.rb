class CreateUserEmailDuplicationLog < DbMigrationConnection
  def up

    run_migration_for_db(EstablishSimpleTokenLogDbConnection.config_key) do
      create_table :user_email_duplication_logs do |t|
        t.column :user1_id, :integer, limit: 8, null: false
        t.column :user2_id, :integer, limit: 8, null: false
        t.column :status, :tinyint, limit: 1, null: false, default: 0
        t.timestamps
      end

      add_index :user_email_duplication_logs, [:user1_id], unique: false, name: 'uid1'
      add_index :user_email_duplication_logs, [:user2_id], unique: false, name: 'uid2'

    end

  end

  def down
    run_migration_for_db(EstablishSimpleTokenLogDbConnection.config_key) do
      drop_table :user_email_duplication_logs
    end
  end
end
