class CreateEntityDrafts < DbMigrationConnection

  def up
    run_migration_for_db(EstablishSimpleTokenCustomizationDbConnection.config_key) do
      create_table :entity_drafts do |t|
        t.column :client_id, :integer, limit: 8, null: false
        t.column :uuid, :integer, limit: 8, null: false
        t.column :creator_admin_id, :integer, limit: 8, null: false
        t.column :last_updated_admin_id, :integer, limit: 8, null: false
        t.column :entity_type, :tinyint, limit: 4, null: false
        t.column :data, :text, null: true
        t.column :activated_at, :integer, limit: 11, null: false
        t.column :status, :tinyint, limit: 4, null: false
        t.timestamps
      end

      add_index :entity_drafts, [:creator_admin_id, :entity_type], unique: false, name: 'creator_admin_id_entity_type'
    end
  end

  def down
    run_migration_for_db(EstablishSimpleTokenCustomizationDbConnection.config_key) do
      drop_table :entity_drafts
    end
  end

end