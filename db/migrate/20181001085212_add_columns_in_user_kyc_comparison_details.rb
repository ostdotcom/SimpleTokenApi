class AddColumnsInUserKycComparisonDetails < DbMigrationConnection
  def up
    run_migration_for_db(EstablishSimpleTokenUserDbConnection.config_key) do
      add_column :user_kyc_comparison_details, :selfie_human_labels_percent, :decimal, precision:5, scale:2,
                 after: :small_face_match_percent, :default => 0, null: false
    end

  end

  def down
    run_migration_for_db(EstablishSimpleTokenUserDbConnection.config_key) do
      remove_column :user_kyc_comparison_details, :selfie_human_labels_percent
    end
  end
end
