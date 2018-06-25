class AddAwsFaceComparisonInVisionDetectFace < DbMigrationConnection
  def up
    run_migration_for_db(EstablishImageProcessingPocDbConnection.config_key) do
      add_column :vision_detect_faces, :aws_face_comparison_response, :text, :after => :rotation_sequence
    end

  end

  def down
    run_migration_for_db(EstablishImageProcessingPocDbConnection.config_key) do
      remove_column :vision_detect_faces, :aws_face_comparison_response
    end

  end
end
