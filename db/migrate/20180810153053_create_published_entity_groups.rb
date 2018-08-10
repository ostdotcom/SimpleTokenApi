class CreatePublishedEntityGroups < DbMigrationConnection

  def up
    run_migration_for_db(EstablishSimpleTokenCustomizationDbConnection.config_key) do
      create_table :published_entity_groups do |t|
        t.column :client_id, :integer, limit: 8, null: false
        t.column :entity_group_id, :integer, limit: 8, null: false
        t.timestamps
      end

      add_index :published_entity_groups, [:client_id], unique: true, name: 'uniq_client_id'
    end
  end

  def down
    run_migration_for_db(EstablishSimpleTokenCustomizationDbConnection.config_key) do
      drop_table :published_entity_groups
    end
  end

end