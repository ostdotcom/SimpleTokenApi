class CreateUserKycComparisonDetails < DbMigrationConnection

  def up

    run_migration_for_db(EstablishSimpleTokenUserDbConnection.config_key) do
      create_table :user_kyc_comparison_details do |t|
        t.column :user_extended_detail_id, :bigint, null: false
        t.column :client_id, :integer, null: false
        t.column :lock_id, :integer, null: true
        t.column :document_dimensions, :string, null: false
        t.column :selfie_dimensions, :string, null: false
        t.column :first_name_match_percent, :decimal, precision:5, scale:2, null: false, default: 0
        t.column :last_name_match_percent, :decimal, precision:5, scale:2, null: false, default: 0
        t.column :birthdate_match_percent, :decimal, precision:5, scale:2, null: false, default: 0
        t.column :document_id_number_match_percent, :decimal, precision:5, scale:2, null: false, default: 0
        t.column :nationality_match_percent, :decimal, precision:5, scale:2, null: false, default: 0
        t.column :big_face_match_percent, :decimal, precision:5, scale:2, null: false, default: 0
        t.column :small_face_match_percent, :decimal, precision:5, scale:2, null: false, default: 0
        t.column :image_processing_status, :tinyint, null: false, default: 0
        t.column :kyc_auto_approved_status, :tinyint, null: false, default: 0
        t.column :client_kyc_auto_approve_settings_id, :integer, null: false, default: 0
        t.timestamps
      end

      add_index :user_kyc_comparison_details, :user_extended_detail_id, unique: true, name: 'uniq_user_extended_id'
      add_index :user_kyc_comparison_details, [:client_id, :kyc_auto_approved_status], name: 'client_auto_approve_kyc_indx'
    end

  end

  def down
    run_migration_for_db(EstablishSimpleTokenUserDbConnection.config_key) do
      drop_table :user_kyc_comparison_details
    end
  end
end
