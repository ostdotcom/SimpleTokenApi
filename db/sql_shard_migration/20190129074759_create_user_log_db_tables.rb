module SqlShardMigration
  class CreateUserLogDbTables < Base

    def up
      run_migration_for_db(db_config_key) do

        create_table :user_utm_logs do |t|
          t.column :user_id, :integer, limit: 8, null: false
          t.column :origin_page, :string, limit: 255
          t.column :utm_type, :string, limit: 50
          t.column :utm_medium, :string, limit: 255
          t.column :utm_source, :string, limit: 255
          t.column :utm_term, :string, limit: 255
          t.column :utm_campaign, :string, limit: 255
          t.column :utm_content, :string, limit: 255
        end

        add_index :user_utm_logs, [:user_id], unique: true, name: 'u_user_id'


        create_table :user_email_duplication_logs do |t|
          t.column :user1_id, :integer, limit: 8, null: false
          t.column :user2_id, :integer, limit: 8, null: false
          t.column :status, :tinyint, limit: 1, null: false, default: 0
          t.timestamps
        end

        add_index :user_email_duplication_logs, [:user1_id], unique: false, name: 'uid1'
        add_index :user_email_duplication_logs, [:user2_id], unique: false, name: 'uid2'



        create_table :user_activity_logs do |t|
          t.column :user_id, :integer, limit: 8, null: false
          t.column :admin_id, :integer, limit: 8, null: true
          t.column :log_type, :tinyint, null: false
          t.column :action, :tinyint, null: false
          t.column :action_timestamp, :bigint, null: false
          t.column :e_data, :text, null: true
          t.timestamps
        end

        add_index :user_activity_logs, [:user_id, :log_type], unique: false, name: 'uid_type'


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



        create_table :edit_kyc_requests do |t|
          t.column :case_id, :integer, limit: 4, null: false
          t.column :admin_id, :integer, limit: 4, null: false
          t.column :user_id, :integer, limit: 4, null: false
          t.column :ethereum_address, :blob #encrypted
          t.column :update_action, :tinyint, limit: 1, null: false, default: 0
          t.column :debug_data, :text
          t.column :status, :integer, limit: 1, default: 0
          t.timestamps
        end

        add_index :edit_kyc_requests, [:case_id, :status], unique: false, name: 'case_id_status'


        create_table :image_processing_logs do |t|
          t.column :user_kyc_comparison_detail_id, :bigint, null: false
          t.column :service_used, :tinyint, limit: 2, null: false
          t.column :input_params, :text, null: false
          t.column :debug_data, :mediumblob, null: true
          t.timestamps
        end

        add_index :image_processing_logs, :user_kyc_comparison_detail_id, name: 'user_kyc_comparison_detail_indx'

      end
    end

    def down
      run_migration_for_db(db_config_key) do

        drop_table :user_utm_logs
        drop_table :user_email_duplication_logs
        drop_table :user_activity_logs
        drop_table :user_kyc_duplication_logs
        drop_table :edit_kyc_requests
        drop_table :image_processing_logs

      end
    end

    def database_shard_type
      'user_log'
    end

  end
end
