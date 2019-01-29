# frozen_string_literal: true
module GlobalConstant

  class Shard

    # GlobalConstant::Shard

    def self.primary_shard_identifier
      "shard_1"
    end

    def self.shards_to_process_for_crons
      all_shard_identifiers - [primary_shard_identifier]
    end

    def self.all_shard_identifiers
      @all_shard_identifiers ||= shard_config.keys
    end

    def self.shard_config
      @sql_config ||= sql_shard_config.fetch('shards', {}).with_indifferent_access
    end

    def self.model_config
      @model_config ||= sql_shard_config.fetch('models', {}).with_indifferent_access
    end

    # base_model -> config
    # {
    #     User => {:table => "users", :module => User::Methods, :database_shard_type=>"user"},
    #     UserSecret => {:table => "user_secrets", :module => UserSecret::Methods, :database_shard_type=>"user"},
    #     UserKycDetail => {:table => "user_kyc_details", :module => UserKycDetail::Methods, :database_shard_type=>"user"},
    #     UserKycComparisonDetail => {:table => "user_kyc_comparison_details", :module => UserKycComparisonDetail::Methods, :database_shard_type=>"user"},
    #     UserExtendedDetail => {:table => "user_extended_details", :module => UserExtendedDetail::Methods, :database_shard_type=>"user"}
    #     }
    # }
    def self.sql_shards_models
      @@sql_shards_models
    end


    # database_shard_type -> shard_identifier -> config
    # {
    #     :user => {:shard_1 => {:model_suffix => "shard1", :connection_model => EstablishOstKycUserShard1DbConnection(abstract)},
    #               :shard_2 => {:model_suffix => "shard2", :connection_model => EstablishOstKycUserShard2DbConnection(abstract)}
    #     }
    # }
    def self.sql_shards_db_config
      @@sql_shards_db_config
    end


    def self.get_model(base_model, params)
      return base_model unless params[:shard_identifier]
      shard_identifier = params[:shard_identifier].to_sym

      model_config = sql_shards_models[base_model]
      database_shard_type = model_config[:database_shard_type]
      shard_db_config = sql_shards_db_config[database_shard_type.to_sym][shard_identifier]

      return base_model if model_config.blank? || shard_db_config.blank?

      class_name = "#{base_model}#{shard_db_config[:model_suffix].camelize}"
      c = def_class.const_get(class_name) rescue nil
      unless c

        klass = Class.new(shard_db_config[:connection_model]) do
          self.table_name = model_config[:table]

          define_singleton_method :shard_identifier do
            shard_identifier.to_s
          end

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

      s_s_d_c, s_s_m = {}, {}
      model_config.each do |database_shard_type, s_data|
        s_data.each do |model_name, data|
          cl = model_name.constantize
          s_s_m[cl] = data.deep_symbolize_keys
          class_module = cl.const_defined?("Methods") ? "#{model_name}::Methods" : "ActiveSupport::Concern"
          s_s_m[cl].merge!({module: class_module.constantize, database_shard_type: database_shard_type})
          cl.class_eval {include ShardHelper}
        end


        s_d_c = {}
        shard_config.each do |shard_identifier, data|
          db_config_key = get_db_config_key(database_shard_type, shard_identifier)
          connection_model_name = "Establish#{db_config_key.camelize}DbConnection"
          c = Object.const_get(connection_model_name) rescue nil

          unless c
            klass = Class.new(ApplicationRecord) do
              self.abstract_class = true
            end
            Object.const_set(connection_model_name, klass)
            c = Object.const_get(connection_model_name)
            c.establish_connection("#{db_config_key}_#{Rails.env}".to_sym)
          end

          data[:connection_model] = c
          s_d_c[shard_identifier.to_sym] = data.deep_symbolize_keys
        end
        s_s_d_c[database_shard_type.to_sym] = s_d_c


      end
      class_variable_set('@@sql_shards_models', s_s_m)
      class_variable_set('@@sql_shards_db_config', s_s_d_c)
    end


    def self.get_db_config_key(database_shard_type, shard_identifier)
      "ost_kyc_#{database_shard_type.to_s}_#{shard_identifier.to_s}"
    end

    private

    def self.def_class
      ::Object
    end

    def self.sql_shard_config
      @config ||= begin
        template = ERB.new File.new("#{Rails.root}/config/sql_shards.yml").read
        YAML.load(template.result(binding)).fetch('sql_shard_config', {}) || {}
      end
    end

  end

end