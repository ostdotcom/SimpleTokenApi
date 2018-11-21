class AddUuidInClient < DbMigrationConnection
  def up
    run_migration_for_db(EstablishSimpleTokenClientDbConnection.config_key) do
      add_column :clients, :uuid, :string, limit: 100,  after: :name, :null => true

      add_index :clients, [:uuid], unique: true, name: 'uuid'

    end
  end

  def down
    run_migration_for_db(EstablishSimpleTokenClientDbConnection.config_key) do
      remove_column :clients, :uuid
    end
  end


end