class CreateEntityGroups < DbMigrationConnection

  def up
    run_migration_for_db(EstablishSimpleTokenCustomizationDbConnection.config_key) do
      create_table :entity_groups do |t|
        t.column :uuid, :string, limit: 32, null: false
        t.column :creator_admin_id, :integer, limit: 8, null: false
        t.column :status, :tinyint, limit: 4, null: false
        t.column :activated_at, :integer, null: true
        t.timestamps
      end

      add_index :entity_groups, [:uuid], unique: true, name: 'uniq_uuid'
      add_index :entity_groups, [:creator_admin_id], unique: false, name: 'creator_admin_id'
    end
  end

  def down
    run_migration_for_db(EstablishSimpleTokenCustomizationDbConnection.config_key) do
      drop_table :entity_groups
    end
  end

end
