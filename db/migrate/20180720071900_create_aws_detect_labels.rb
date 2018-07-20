class CreateAwsDetectLabels < DbMigrationConnection
  def up
    run_migration_for_db(EstablishImageProcessingPocDbConnection.config_key) do
      create_table :aws_detect_labels do |t|
        t.column :case_id, :integer, null: false
        t.column :document_id_orientation, :string
        t.column :document_id_labels, :text
        t.column :selfie_orientation, :string
        t.column :selfie_labels, :text
        t.timestamps
      end
    end
  end

  def down
    run_migration_for_db(EstablishImageProcessingPocDbConnection.config_key) do
      drop_table :aws_detect_labels
    end
  end
end
