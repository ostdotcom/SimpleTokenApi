class CreateVisionAwsCompareFaces < DbMigrationConnection

  def up

    run_migration_for_db(EstablishImageProcessingPocDbConnection.config_key) do

      create_table :vision_aws_compare_faces do |t|
        t.column :case_id, :integer, limit: 8, null: false
        t.column :orientation_detected, :string
        t.column :actual_orientation_document_match, :string
        t.column :document_rotation_iteration, :tinyint
        t.column :actual_orientation_selfie_match, :string
        t.column :selfie_rotation_iteration, :tinyint
        t.column :aws_face_comparison_response, :text
        t.column :big_image_similarity_percent, :integer
        t.column :small_image_similarity_percent, :integer
        t.timestamps
      end

    end

  end

  def down
    run_migration_for_db(EstablishImageProcessingPocDbConnection.config_key) do
      drop_table :vision_aws_compare_faces
    end
  end
end
