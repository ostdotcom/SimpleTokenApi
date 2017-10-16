class CreateUserKycDuplicationLogs < DbMigrationConnection
  def up

    run_migration_for_db(EstablishSimpleTokenLogDbConnection.config_key) do
      create_table :user_kyc_duplication_logs do |t|

        t.column :user1_id, :integer, limit: 8, null: false
        t.column :user2_id, :integer, limit: 8, null: false
        t.column :user_extended_details1_id, :integer, limit: 8, null: false
        t.column :user_extended_details2_id, :integer, limit: 8, null: false
        t.column :duplicate_type, :tinyint, limit: 1, null: false, default: 1
        t.column :status, :tinyint, limit: 1, null: false, default: 1

        t.timestamps
      end

      add_index :user_kyc_duplication_logs, [:user1_id, :status], unique: false, name: 'uid_uedid_status1'
      add_index :user_kyc_duplication_logs, [:user2_id, :status], unique: false, name: 'uid_uedid_status2'

    end

  end

  def down
    run_migration_for_db(EstablishSimpleTokenLogDbConnection.config_key) do
      drop_table :user_kyc_duplication_logs
    end
  end
end
