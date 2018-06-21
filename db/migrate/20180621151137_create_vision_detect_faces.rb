
class CreateVisionDetectFaces < DbMigrationConnection

  def up

    run_migration_for_db(EstablishImageProcessingPocDbConnection.config_key) do

      create_table :vision_detect_faces do |t|
        t.column :case_id, :integer, limit: 8, null: false
        t.column :rotate_90, :text
        t.column :rotate_180, :text
        t.column :rotate_270, :text
        t.column :rotate_360, :text
        t.column :rotate_0, :text
        t.timestamps
      end

    end

  end

  def down
    run_migration_for_db(EstablishImageProcessingPocDbConnection.config_key) do
      drop_table :vision_detect_faces
    end
  end
end
