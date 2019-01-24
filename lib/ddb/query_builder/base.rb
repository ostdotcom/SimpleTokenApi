module Ddb
  module QueryBuilder
    class Base
      def initialize(params, table_options)
        @params = params
        @table_options = table_options
        @expression_attribute_values = {}
      end

      def get_key_hash
        key_hash = {}
        @params[:key_conditions].each do | condition |
          key_hash[get_short_key_name(condition)] = {value: condition[:attribute].values.join("_"),
                                                     operator: condition[:operator] } if get_short_key_name(condition)
        end
        key_hash
      end

      def get_key_hash_from_indexes

      end

      def get_short_key_name(condition)
        @table_options[:merged_columns].key({keys: condition[:attribute].keys})
      end


      def variable_mappings
        @table_options[:variable_mapping]
      end




    end
  end
end