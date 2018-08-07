class CreatePublishedEntities < DbMigrationConnection

  def up
    run_migration_for_db(EstablishSimpleTokenCustomizationDbConnection.config_key) do
      create_table :published_entities do |t|
        t.column :client_id, :integer, limit: 8, null: false
        t.column :draft_id, :integer, limit: 8, null: false
        t.column :entity_type, :tinyint, limit: 4, null: false
        t.timestamps
      end

      add_index :published_entities, [:client_id, :entity_type], unique: false, name: 'client_id_entity_type'
    end
  end

  def down
    run_migration_for_db(EstablishSimpleTokenCustomizationDbConnection.config_key) do
      drop_table :published_entities
    end
  end

end