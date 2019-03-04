class CreateClientShard < DbMigrationConnection
  def up
    run_migration_for_db(EstablishSimpleTokenClientDbConnection.config_key) do

      create_table :client_shards do |t|
        t.column :client_id, :integer, limit: 8, null: false
        t.column :shard_identifier, :string, limit: 10, null: false
        t.timestamps
      end

      add_index :client_shards, [:client_id], unique: true, name: 'uniq_client_id'
    end

    Client.all.each do |client|
      ClientShard.create!(client_id: client.id, shard_identifier: GlobalConstant::SqlShard.primary_shard_identifier.to_s)
    end

  end

  def down
    run_migration_for_db(EstablishSimpleTokenClientDbConnection.config_key) do
      drop_table :client_shards
    end
  end
end

