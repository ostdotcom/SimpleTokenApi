class CreateVisionCompareTexts < DbMigrationConnection

  def up

    run_migration_for_db(EstablishImageProcessingPocDbConnection.config_key) do

      create_table :vision_compare_texts do |t|
        t.column :case_id, :integer, limit: 8, null: false
        t.column :request_time, :integer, limit: 8, null: false, default: 0
        t.column :first_name_match_percent, :decimal, precision:6, scale:3, null: false, default: 0
        t.column :last_name_match_percent, :decimal, precision:6, scale:3, null: false, default: 0
        t.column :birthdate_match_percent, :decimal, precision:6, scale:3, null: false, default: 0
        t.column :document_id_number_match_percent, :decimal, precision:6, scale:3, null: false, default: 0
        t.column :nationality_match_percent, :decimal, precision:6, scale:3, null: false, default: 0
        t.column :debug_data, :text, null: true
        t.timestamps
      end

      add_index :vision_compare_texts, [:case_id], unique: true, name: 'unique_case_id'

    end

  end

  def down
    run_migration_for_db(EstablishImageProcessingPocDbConnection.config_key) do
      drop_table :vision_compare_texts
    end
  end
end