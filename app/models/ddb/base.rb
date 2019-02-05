module Ddb
  class Base

    include Ddb::Table


    def initialize(params, options = {})
      @shard_id = params[:shard_id]
      @use_column_mapping = options[:use_column_mapping]
      puts "----- #{@use_column_mapping}"

      set_table_name
    end


    def initialize_instance_variables(hash)
      hash.each do |k, v|
        instance_variable_set("@#{k}", v)
        self.class.send(:attr_accessor, k)
      end if hash.present?
      self
    end

    def set_table_name
      table_info[:name] = "#{Rails.env}_#{@shard_id}_#{self.class.raw_table_name}"
    end

    def use_column_mapping?
      @use_column_mapping == false ? false : true
    end

  end
end


