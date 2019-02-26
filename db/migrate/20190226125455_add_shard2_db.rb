class AddShard2Db < DbMigrationConnection

  def up
    shard_identifiers = ["shard_2"]
    shard_identifiers.each do |shard_identifier|
      SqlShardMigration::CreateUserDbTables.new(shard_identifier: shard_identifier).up
      SqlShardMigration::CreateUserLogDbTables.new(shard_identifier: shard_identifier).up
      SqlShardMigration::CreateAmlDbTables.new(shard_identifier: shard_identifier).up
    end
  end

  def down
    shard_identifiers = ["shard_2"]
    shard_identifiers.each do |shard_identifier|
      SqlShardMigration::CreateUserDbTables.new(shard_identifier: shard_identifier).down
      SqlShardMigration::CreateUserLogDbTables.new(shard_identifier: shard_identifier).down
      SqlShardMigration::CreateAmlDbTables.new(shard_identifier: shard_identifier).down
    end
  end

end