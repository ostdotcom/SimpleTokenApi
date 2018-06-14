class CreateRekognitionDetectFace < DbMigrationConnection

  def up

    run_migration_for_db(EstablishImageProcessingPocDbConnection.config_key) do

      create_table :rekognition_detect_faces do |t|
        t.column :case_id, :integer, limit: 8, null: false
        t.column :request_time, :integer, limit: 8, null: false, default: 0

        t.column :debug_data_selfie, :text, null: true
        t.column :debug_data_document, :text, null: true

        t.column :orientation_selfie, :text, null: true
        t.column :confidence_selfie, :integer, limit: 8, null: true

        t.column :orientation_document, :text, null: true
        t.column :confidence_document, :integer, limit: 8, null: true

        t.timestamps
      end

    end

  end

  def down
    run_migration_for_db(EstablishImageProcessingPocDbConnection.config_key) do
      drop_table :rekognition_detect_faces
    end
  end

end
