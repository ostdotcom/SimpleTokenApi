namespace :onetimer do

  # rake RAILS_ENV=development onetimer:run_mysql_shard_migration shard_identifier=shard_2
  task :run_mysql_shard_migration => :environment do

    migration_path = 'db/sql_shard_migration'

    shard_identifier = ENV['shard_identifier']

    Dir["#{migration_path}/[0-9]*_*.rb"].sort.each do |file_path|
      basename = File.basename(file_path, '.rb').gsub(/([0-9]+_)/,'')
      classname = "sql_shard_migration/#{basename}".camelize
      DbMigrationConnection.const_get(classname).new(shard_identifier: shard_identifier).up
    end


  end

end