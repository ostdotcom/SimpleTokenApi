class DbMigrationConnection < ActiveRecord::Migration[5.1]

  # Sanitize params recursively
  #
  # * Author: Kedar
  # * Date: 09/10/2017
  # * Reviewed By: Sunil Khedar
  #
  # @param [Hash] passed_params
  #
  def run_migration_for_db(config_key, &block)
    template = ERB.new File.new("#{Rails.root}/config/database.yml").read
    config = (YAML.load(template.result(binding)))[config_key]
    db_name = config["database"]
    config.except!("database")
    # puts config
    @connection = ApplicationRecord.establish_connection(config).connection
    execute "CREATE DATABASE IF NOT EXISTS " + db_name + " DEFAULT CHARACTER SET utf8 COLLATE utf8_unicode_ci;"
    execute "USE " + db_name
    yield if block.present?
    @connection = ApplicationRecord.establish_connection(Rails.env.to_sym).connection
  end

end