class CreateEntityDrafts < DbMigrationConnection

  def up
    run_migration_for_db(EstablishSimpleTokenCustomizationDbConnection.config_key) do
      create_table :entity_drafts do |t|
        t.column :client_id, :integer, null: false
        t.column :last_updated_admin_id, :integer, null: false
        t.column :data, :text, null: true
        t.column :status, :tinyint, limit: 4, null: false
        t.timestamps
      end

    end
  end

  def down
    run_migration_for_db(EstablishSimpleTokenCustomizationDbConnection.config_key) do
      drop_table :entity_drafts
    end
  end

end