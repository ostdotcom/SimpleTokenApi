class CreateEntityGroupDrafts < DbMigrationConnection

  def up
    run_migration_for_db(EstablishSimpleTokenCustomizationDbConnection.config_key) do
      create_table :entity_group_drafts do |t|
        t.column :entity_group_id, :integer, limit: 8, null: false
        t.column :entity_draft_id, :integer, limit: 8, null: false
        t.column :entity_type, :tinyint, limit: 4, null: false
        t.timestamps
      end

      add_index :entity_group_drafts, [:entity_group_id, :entity_type], unique: true, name: 'uniq_entity_group_id_entity_type'
    end
  end

  def down
    run_migration_for_db(EstablishSimpleTokenCustomizationDbConnection.config_key) do
      drop_table :entity_group_drafts
    end
  end

end
