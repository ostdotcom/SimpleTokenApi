class AddDobColumnInVisionCompareText < DbMigrationConnection
  def self.up
    run_migration_for_db(EstablishImageProcessingPocDbConnection.config_key) do
      add_column :vision_compare_texts, :date_of_birth, :string, limit: 50, null: true, after: :debug_data
      add_column :vision_compare_texts, :orientation, :string, limit: 20, null: true, after: :date_of_birth
    end
  end

  def self.down
    run_migration_for_db(EstablishImageProcessingPocDbConnection.config_key) do
      remove_column :vision_compare_texts, :date_of_birth
      remove_column :vision_compare_texts, :orientation
    end
  end
end