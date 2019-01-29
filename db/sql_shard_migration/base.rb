module SqlShardMigration
  class Base < DbMigrationConnection

    def initialize(params)
      @shard_identifier = params[:shard_identifier]
    end

    def db_config_key
      GlobalConstant::Shard.get_db_config_key(database_shard_type, @shard_identifier) + "_#{Rails.env.to_s}"
    end

    def database_shard_type
      fail 'unimplementd method database shard type'
    end

  end
end
