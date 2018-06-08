class CreateRekognitionCompareTexts < DbMigrationConnection

  def up

    run_migration_for_db(EstablishImageProcessingPocDbConnection.config_key) do

      create_table :rekognition_compare_texts do |t|
        t.column :case_id, :integer, limit: 8, null: false
        t.column :request_time, :integer, limit: 8, null: false
        t.column :first_name_match_percentage, :decimal, precision:6, scale:3, null: false, default: 0
        t.column :last_name_match_percentage, :decimal, precision:6, scale:3, null: false, default: 0
        t.column :dob_match_percentage, :decimal, precision:6, scale:3, null: false, default: 0
        t.column :document_id_match_percentage, :decimal, precision:6, scale:3, null: false, default: 0
        t.column :nationality_match_percentage, :decimal, precision:6, scale:3, null: false, default: 0
        t.column :debug_data, :text, null: true
        t.timestamps
      end

    end

  end

  def down
    run_migration_for_db(EstablishImageProcessingPocDbConnection.config_key) do
      drop_table :rekognition_compare_texts
    end
  end
end
