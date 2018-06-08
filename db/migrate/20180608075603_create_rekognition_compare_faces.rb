class CreateRekognitionCompareFaces < DbMigrationConnection

  def up

    run_migration_for_db(EstablishImageProcessingPocDbConnection.config_key) do

      create_table :rekognition_compare_faces do |t|
        t.column :case_id, :integer, limit: 8, null: false
        t.column :similarity_percentage, :decimal, precision:6, scale:3, null: true
        t.column :face_matches, :text, null: true
        t.column :debug_data, :text, null: true
        t.timestamps
      end

    end

  end

  def down
    run_migration_for_db(EstablishImageProcessingPocDbConnection.config_key) do
      drop_table :rekognition_compare_faces
    end
  end

end
