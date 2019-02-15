module SqlShardMigration
  class CreateUserDbTables < Base

    def up
      run_migration_for_db(db_config_key) do

        create_table :users do |t|
          t.column :client_id, :integer, limit: 4, null: false
          t.column :user_secret_id, :integer, limit: 4, null: true
          t.column :email, :string, null: true
          t.column :password, :string, null: true
          t.column :bt_name, :string, null: true
          t.column :properties, :tinyint, null: false, default: 0
          t.column :last_logged_in_at, :integer, null: true
          t.column :status, :tinyint, limit: 1, null: false, default: 1
          t.timestamps
        end

        add_index :users, [:client_id,:email], unique: true, name: 'uniq_client_id_and_email'
        add_index :users, :bt_name, unique: true, name: 'uniq_bt_name'

        execute ("ALTER TABLE users AUTO_INCREMENT = 11000")

        create_table :user_secrets do |t|
          t.column :login_salt, :blob, null: false #encrypted
          t.timestamps
        end


        create_table :user_kyc_details do |t|
          t.column :client_id, :integer, limit: 4, null: false
          t.column :user_id, :integer, limit: 8, null: false
          t.column :user_extended_detail_id, :integer, limit: 8, null: false
          t.column :aml_user_id, :string, null: true
          t.column :kyc_confirmed_at, :integer, limit: 4, null: true
          t.column :token_sale_participation_phase, :integer, limit: 4, null: false

          t.column :pos_bonus_percentage, :decimal, precision: 5, scale: 2, limit: 4, null: true
          t.column :alternate_token_id_for_bonus, :integer, limit: 8, null: true
          t.column :submission_count, :integer, limit: 4, null: false


          t.column :kyc_duplicate_status, :integer, limit: 4, null: false
          t.column :email_duplicate_status, :tinyint, limit: 1, null: false, default: 0

          t.column :aml_status, :integer, limit: 4, null: false
          t.column :admin_status, :integer, limit: 4, null: false
          t.column :admin_action_types, :tinyint, limit: 1, null: false
          t.column :whitelist_status, :tinyint, limit: 1, null: false
          t.column :status, :tinyint, limit: 1, null: false, default: 1


          t.column :last_acted_by, :integer, limit: 8, null: true
          t.column :last_admin_id, :integer, limit: 8, null: false, default: 0

          t.column :last_acted_timestamp, :integer, limit: 4, null: true
          t.column :last_reopened_at, :integer, limit: 4, null: true, default: 0
          t.column :qualify_types, :tinyint, limit: 1, null: false, default: 0
          t.timestamps
        end

        add_index :user_kyc_details, :user_id, unique: true, name: 'uniq_user_id'
        add_index :user_kyc_details, [:client_id, :status, :user_extended_detail_id], unique: true, name: 'client_id_status_user_extended_detail_id'


        create_table :user_kyc_comparison_details do |t|
          t.column :user_extended_detail_id, :bigint, null: false
          t.column :client_id, :integer, null: false
          t.column :lock_id, :string, null: true
          t.column :document_dimensions, :string, null: true
          t.column :selfie_dimensions, :string, null: true
          t.column :first_name_match_percent, :decimal, precision:5, scale:2, null: false, default: 0
          t.column :last_name_match_percent, :decimal, precision:5, scale:2, null: false, default: 0
          t.column :birthdate_match_percent, :decimal, precision:5, scale:2, null: false, default: 0
          t.column :document_id_number_match_percent, :decimal, precision:5, scale:2, null: false, default: 0
          t.column :nationality_match_percent, :decimal, precision:5, scale:2, null: false, default: 0
          t.column :big_face_match_percent, :decimal, precision:5, scale:2, null: false, default: 0
          t.column :small_face_match_percent, :decimal, precision:5, scale:2, null: false, default: 0
          t.column :selfie_human_labels_percent, :decimal, precision:5, scale:2, default: 0, null: false
          t.column :image_processing_status, :tinyint, null: false, default: 0
          t.column :auto_approve_failed_reasons, :integer , null: false, default: 0
          t.column :client_kyc_pass_settings_id, :integer, null: false, default: 0
          t.timestamps
        end

        add_index :user_kyc_comparison_details, :user_extended_detail_id, unique: true, name: 'uniq_user_extended_id'



        create_table :user_extended_details do |t|
          t.column :user_id, :integer, limit: 8, null: false
          t.column :first_name, :string, null: false
          t.column :last_name, :string, null: false
          t.column :kyc_salt, :blob, null: false
          t.column :birthdate, :blob, null: false #encrypted
          t.column :street_address, :blob, null: true #encrypted
          t.column :city, :blob, null: true #encrypted
          t.column :state, :blob, null: true #encrypted
          t.column :country, :blob, null: false #encrypted
          t.column :postal_code, :blob, null: true #encrypted
          t.column :ethereum_address, :blob, null: true #encrypted
          t.column :estimated_participation_amount, :blob, null: true #encrypted
          t.column :document_id_number, :blob, null: false #encrypted
          t.column :nationality, :blob, null: false #encrypted
          t.column :document_id_file_path, :blob, null: false #encrypted
          t.column :selfie_file_path, :blob, null: false #encrypted
          t.column :residence_proof_file_path, :blob, null: true #encrypted
          t.column :investor_proof_files_path, :blob, null: true #encrypted
          t.column :extra_kyc_fields, :blob, null: true #encrypted
          t.timestamps
        end

        add_index :user_extended_details, :user_id, unique: false, name: 'uniq_user_id'



        create_table :md5_user_extended_details do |t|
          t.column :user_id, :integer, limit: 8, null: false
          t.column :user_extended_detail_id, :integer, limit: 8, null: false
          t.column :birthdate, :string, null: false
          t.column :street_address, :string, null: true
          t.column :city, :string, null: true
          t.column :state, :string, null: true
          t.column :country, :string, null: false
          t.column :postal_code, :string, null: true
          t.column :ethereum_address, :string, null: true
          t.column :estimated_participation_amount, :string, null: true
          t.column :document_id_number, :string, null: false
          t.column :nationality, :string, null: false
          t.timestamps
        end

        add_index :md5_user_extended_details, :user_extended_detail_id, unique: true, name: 'uniq_user_extended_detail_id'


        create_table :deleted_users do |t|
          t.column :client_id, :integer, null: false
          t.column :deleted_by_admin, :integer, null: false
          t.column :email, :string, null: false
          t.column :user_id, :integer, null: false
          t.column :status, :tinyint, limit: 1, null: false, default: 1
          t.timestamps
        end


      end
    end

    def down
      run_migration_for_db(db_config_key) do

        drop_table :users
        drop_table :user_secrets
        drop_table :user_kyc_details
        drop_table :user_kyc_comparison_details
        drop_table :user_extended_details
        drop_table :md5_user_extended_details
        drop_table :deleted_users

      end
    end

    def database_shard_type
      'user'
    end

  end
end
