class CreateClientTemplates < DbMigrationConnection

  def up
    run_migration_for_db(EstablishSimpleTokenClientDbConnection.config_key) do
      create_table :client_templates do |t|
        t.column :client_id, :integer, limit: 8, null: false
        t.column :template_type, :tinyint, null: false
        t.column :data, :text, null: true
        t.timestamps
      end

      add_index :client_templates, [:client_id, :template_type], unique: true, name: 'uniq_client_id_and_template_type'
    end

  end

  def down
    run_migration_for_db(EstablishSimpleTokenClientDbConnection.config_key) do
      drop_table :client_templates
    end
  end

end

