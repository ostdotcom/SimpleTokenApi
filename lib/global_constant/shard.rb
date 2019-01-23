# frozen_string_literal: true
module GlobalConstant

  class Shard

    # GlobalConstant::Shard

    def self.sql_config
      @sql_config ||= config.fetch('sql_config', {}).with_indifferent_access
    end

    def self.sql_shards_models
      @@sql_shards_models
    end

    def self.sql_shards_db_config
      @@sql_shards_db_config
    end

    def self.total_shards
      @total_shards ||= sql_shards_db_config.length
    end

    def self.shard_identifiers
      @shard_identifiers ||= sql_shards_db_config.keys
    end

    def self.get_model(base_model, params)
      return base_model unless params[:shard_identifier]
      shard_identifier = params[:shard_identifier].to_sym

      model_config = sql_shards_models[base_model]
      shard_db_config = sql_shards_db_config[shard_identifier]
      return base_model if model_config.blank? || shard_db_config.blank?

      class_name = "#{base_model}#{shard_db_config[:model_suffix].camelize}"
      c = def_class.const_get(class_name) rescue nil
      unless c

        klass = Class.new(shard_db_config[:connection_model]) do
          self.table_name = model_config[:table]
          include model_config[:module] if model_config[:module].present?
        end

        def_class.const_set(class_name, klass)
        c = def_class.const_get(class_name)
      end

      c
    end

    def self.load_config
      return if @loaded
      @loaded = true

      s_d_c = {}
      sql_config[:db].each do |shard_identifier, data|
        connection_model_name = "Establish#{data[:db].camelize}DbConnection"
        c = Object.const_get(connection_model_name) rescue nil

        unless c
          klass = Class.new(ApplicationRecord) do
            self.abstract_class = true
          end
          Object.const_set(connection_model_name, klass)
          c = Object.const_get(connection_model_name)
          c.establish_connection("#{data[:db]}_#{Rails.env}".to_sym)
        end

        data[:connection_model] = c
        s_d_c[shard_identifier.to_sym] = data.deep_symbolize_keys
      end

      class_variable_set('@@sql_shards_db_config', s_d_c)

      m_config = {}
      sql_config[:models].each do |model_name, data|
        cl = model_name.constantize
        m_config[cl] = data.deep_symbolize_keys
        class_module = cl.const_defined?("Methods") ? "#{model_name}::Methods" : "ActiveSupport::Concern"
        m_config[cl].merge!({module: class_module.constantize})
        cl.class_eval {include ShardHelper}
      end
      class_variable_set('@@sql_shards_models', m_config)
    end

    private

    def self.def_class
      ::Object
    end

    def self.config
      @config ||= begin
        template = ERB.new File.new("#{Rails.root}/config/shards.yml").read
        YAML.load(template.result(binding)).fetch('shards', {}) || {}
      end
    end

  end

end