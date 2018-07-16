class RemovePocTables < DbMigrationConnection

  def up
    run_migration_for_db(EstablishImageProcessingPocDbConnection.config_key) do
      drop_table :rekognition_compare_texts
      drop_table :rekognition_detect_faces
      drop_table :rekognition_compare_faces
      drop_table :vision_compare_texts
      drop_table :vision_aws_compare_faces
      drop_table :vision_detect_faces
    end
  end

  def down
  end
end
