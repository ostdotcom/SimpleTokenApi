module Ddb
  module Table
    extend ActiveSupport::Concern

    include Util::ResultHelper

    included do
      cattr_accessor :table_info

      # put item to dynamodb
      #
      # * Author: MAYUR
      # * Date: 01/02/2019
      # * Reviewed By:
      #
      # @param [Hash] item (mandatory) - hash which includes parameters are as follows
      #   item [Hash] (mandatory) - item to be inserted
      #   consistent_read [Boolean] (optional)
      #   return_consumed_capacity [String] (optional)
      #   return_values [String] (optional)
      #   return_item_collection_metrics[String] (optional)
      #
      # @return [Result::Base] - response from dynamodb
      # # attributes in response can be accessed as *r.data[:data][:attributes]
      #
      def put_item(params)

        r = validate_for_ddb_options(params, self.class.allowed_params[:put_item])
        return r unless r.success?

        r = validate_and_format_params(params)
        return r unless r.success?
        params.merge(r.data[:data])

        r = Ddb::QueryBuilder::PutItem.new({params: params, table_info: table_info}).perform
        return r unless r.success?
        ddb_r = Ddb::Api::PutItem.new(params: r.data).perform
        return ddb_r unless ddb_r.success?

        return parse_write_response(ddb_r.data[:data])
      end


      # Delete from dynamodb
      #
      # * Author: MAYUR
      # * Date: 01/02/2019
      # * Reviewed By:
      #
      # @param [Hash] item (mandatory) - hash which includes parameters are as follows
      #   key [Hash] (mandatory) - Primary key
      #   return_item_collection_metrics [String] (optional) ?
      #   return_consumed_capacity [String] (optional)
      #   return_values [String] (optional)
      # @return [Result::Base] - response from dynamodb
      #
      # attributes in response can be accessed as *r.data[:data][:attributes]*
      #

      def delete_item(params)
        r = validate_for_ddb_options(params, self.class.allowed_params[:delete_item])
        return r unless r.success?

        r = validate_and_format_params(params)
        return r unless r.success?

        params.merge(r.data[:data])

        r = Ddb::QueryBuilder::DeleteItem.new({params: params, table_info: table_info}).perform

        return r unless r.success?

        ddb_r = Ddb::Api::DeleteItem.new(params: r.data).perform
        return ddb_r unless ddb_r.success?

        return parse_write_response(ddb_r.data[:data])

      end


      # update item in dynamodb
      #
      # * Author: MAYUR
      # * Date: 01/02/2019
      # * Reviewed By:
      #
      # @param [Hash] item (mandatory) - query hash which includes parameters are as follows
      #   key [Hash] (mandatory)
      #   set [Hash] (optional)
      #   add [Hash] (optional)
      #   remove [Hash] (optional)
      #   return_consumed_capacity [Hash] (optional)
      #   return_item_collection_metrics [String] (optional)
      #   return_values [String] (optional)
      # @return [Result::Base] - response from dynamodb
      # attributes in response can be accessed as *r.data[:data][:attributes]*
      #
      def update_item(params)

        r = validate_for_ddb_options(params, self.class.allowed_params[:update_item])
        return r unless r.success?

        r = validate_and_format_params(params)
        return r unless r.success?

        params = r.data[:data]

        r = Ddb::QueryBuilder::UpdateItem.new({params: params, table_info: table_info}).perform
        return r unless r.success?

        ddb_r = Ddb::Api::UpdateItem.new(params: r.data).perform

        return ddb_r unless ddb_r.success?

        return parse_write_response ddb_r.data[:data]
      end


      # Scan on dynamodb
      #
      # * Author: MAYUR
      # * Date: 01/02/2019
      # * Reviewed By:
      #
      # @param [Hash] query (mandatory) - query hash which includes parameters are as follows
      #   filter_conditions [Hash] (optional)
      #   consistent_read [Boolean] (optional)
      #   exclusive_start_key [Hash] (optional)
      #   return_consumed_capacity [Hash] (optional)
      #   limit [Number] (optional)
      #   projection_expression [Array] (optional)
      #   index_name [String] (optional)
      # @return [Result::Base] - response from dynamodb -
      # items in response can be accessed as *r.data[:data][:items]*
      #
      def scan(params = {})

        r = validate_for_ddb_options(params, self.class.allowed_params[:scan])
        return r unless r.success?

        r = validate_and_format_params(params)
        return r unless r.success?

        query = r.data[:data]

        r = Ddb::QueryBuilder::Scan.new({params: query, table_info: table_info}).perform
        return r unless r.success?

        ddb_r = Ddb::Api::Scan.new(params: r.data).perform

        return ddb_r unless ddb_r.success?

        return parse_multiple_read_response(ddb_r.data[:data])
      end


      # Query on dynamodb
      #
      # * Author: mayur
      # * Date: 01/02/2019
      # * Reviewed By:
      #
      # @param [Hash] query (mandatory) - query hash which includes parameters are as follows
      #   key_conditions [Hash] (mandatory)
      #   filter_conditions [Hash] (optional)
      #   consistent_read [Boolean] (optional)
      #   exclusive_start_key [Hash] (optional)
      #   return_consumed_capacity [String] (optional)
      #   limit [Number] (optional)
      #   projection_expression [Array] (optional)
      #   index_name [String] (optional)
      # @return [Result::Base] - response from dynamodb
      # items in response can be accessed as *r.data[:data][:items]*

      def query(params)
        r = validate_for_ddb_options(params, self.class.allowed_params[:query])
        return r unless r.success?

        r = validate_and_format_params(params)
        return r unless r.success?

        query = r.data[:data]

        r = Ddb::QueryBuilder::Query.new({params: query, table_info: table_info}).perform
        return r unless r.success?

        ddb_r = Ddb::Api::Query.new(params: r.data).perform
        return ddb_r unless ddb_r.success?

        return parse_multiple_read_response(ddb_r.data[:data])

      end


      # get_item from dynamodb
      #
      # * Author: MAYUR
      # * Date: 01/02/2019
      # * Reviewed By:
      #
      # @param [Hash] item (mandatory) - hash which includes parameters are as follows
      #   key [Hash] (mandatory) - Primary key
      #   consistent_read [Boolean] (optional)
      #   return_consumed_capacity [String] (optional)
      #   projection_expression [Array] (optional)
      # @return [Result::Base] - response from dynamodb
      # # items in response can be accessed as *r.data[:data][:item]*
      #

      def get_item(params)
        r = validate_for_ddb_options(params, self.class.allowed_params[:get_item])
        return r unless r.success?
        
        r = validate_and_format_params(params)
        return r unless r.success?

        get_hash = r.data[:data]

        r = Ddb::QueryBuilder::GetItem.new({params: get_hash, table_info: table_info}).perform
        return r unless r.success?

        ddb_r = Ddb::Api::GetItem.new(params: r.data).perform
        return ddb_r unless ddb_r.success?

        parse_get_response ddb_r.data[:data]
      end


      # Batch write in dynamo db
      #
      # * Author: MAYUR
      # * Date: 01/02/2019
      # * Reviewed By:
      #
      # @param [Hash] items (mandatory) - query hash which includes parameters are as follows
      #   items [Hash] (mandatory)
      #
      def batch_write(params)
        items_list, resp_list = [], []
        r = validate_for_ddb_options(params, self.class.allowed_params[:batch_write])
        return r unless r.success?

        params[:items].each do |item|
          r = validate_and_format_params(item: item)
          return r unless r.success?
          items_list << r.data[:data][:item]
        end

        r = Ddb::QueryBuilder::BatchWrite.new({params: {items: items_list}, table_info: table_info}).perform
        return r unless r.success?

        ddb_r = Ddb::Api::BatchWrite.new(params: r.data).perform
        return ddb_r if ddb_r.success?

        list = ddb_r.data[:data]
        list.each do |l|
          resp_list << parse_response(l["put_request"]["item"])
        end

        error_with_identifier('unprocessed_entities',
                              'sb_1',
                              [],
                              '',
                              {unprocessed: resp_list}
        )
      end


      # parses response from write operations(i.e. put, delete, update)
      #
      # * Author: MAYUR
      # * Date: 01/02/2019
      # * Reviewed By:
      #
      # @param [Hash] data (mandatory) - it includes response from Ddb
      # @return [Result::Base] - formatted_response
      #
      def parse_write_response(data)
        attributes = parse_response(data[:attributes])

        initialize_instance_variables(attributes) if attributes.present?

        consumed_capacity = data[:consumed_capacity]

        item_collection_metrics = data[:item_collection_metrics]


        success_with_data(data: {attributes: attributes, consumed_capacity: consumed_capacity,
                                 item_collection_metrics: item_collection_metrics})

      end


      # parses response from multiple read operations(i.e. query,scan)
      #
      # * Author: MAYUR
      # * Date: 01/02/2019
      # * Reviewed By:
      #
      # @param [Hash] data (mandatory) - it includes response from Ddb
      # @return [Result::Base] - formatted_response
      #
      def parse_multiple_read_response(data)

        instance_array = []

        parsed_resp = parse_response_array(data[:items])

        last_evaluated_key = format_last_eval_key data[:last_evaluated_key]

        return_consumed_capacity = data[:consumed_capacity]

        parsed_resp.each do |resp|
          instance_array << self.class.new(@params, @options).initialize_instance_variables(resp)
        end

        success_with_data(data: {items: instance_array,
                                 last_evaluated_key: last_evaluated_key,
                                 return_consumed_capacity: return_consumed_capacity,

        })

      end


      # parses response from single read operations(i.e. get_item)
      #
      # * Author: MAYUR
      # * Date: 01/02/2019
      # * Reviewed By:
      #
      # @param [Hash] data (mandatory) - it includes response from Ddb
      # @return [Result::Base] - formatted_response
      #
      def parse_get_response(data)
        resp_item = data[:item]
        return_consumed_capacity = data[:consumed_capacity]
        resp_item = parse_response(resp_item)
        resp_item = initialize_instance_variables(resp_item)
        success_with_data(data: {item: resp_item, consumed_capacity: return_consumed_capacity})
      end


      # validate parameters for ddb action functions
      #
      # * Author: MAYUR
      # * Date: 01/02/2019
      # * Reviewed By:
      #
      # @param item [Hash] (mandatory)
      # @param params [Hash] (mandatory)
      # @return [Result::Base] -
      #
      def validate_for_ddb_options(item, params)
        mandatory_params = params[:mandatory]
        optional_params = params[:optional]
        return error_with_identifier('mandatory_params_missing',
                                     'd_t_vfdo_1',
                                     (mandatory_params - item.keys)
        ) if (mandatory_params - item.keys).present?

        mandatory_params.each do |mandatory_param|
          return error_with_identifier('mandatory_params_missing',
                                       'd_t_vfdo_2'
          ) if item[mandatory_param].blank?
        end
        return error_with_identifier('unexpected_params_present',
                                     'd_t_vfdo_3',
                                     (item.keys - (optional_params + mandatory_params))
        ) if (item.keys - (mandatory_params + optional_params)).present?
        success
      end


      # mapping (i.e. full name -> short name conversion )
      #         operations done: [validate, merge columns, long to short, value processed to ddb format]
      #
      # * Author: MAYUR
      # * Date: 01/02/2019
      # * Reviewed By:
      #
      # @param params [Hash] (mandatory)
      # @return [Result Base]
      #
      def validate_and_format_params(params)
        keys_in_params = params.keys
        [:key, :set, :add, :key_conditions, :item ].each do |operation|
          next unless keys_in_params.include?(operation)
          r = validate_and_map_params(params[operation])
          return r unless r.success?
          params[operation] = r.data[:data]
        end

        [:remove, :projection_expression  ].each do |operation|
          next unless keys_in_params.include?(operation)
          r = map_list_to_be_name(params[operation])
          return r unless r.success?
          params[operation] = r.data[:data]
        end

        unless params[:filter_conditions].nil?
          r = validate_and_map_params params[:filter_conditions][:conditions]
          params[:filter_conditions][:conditions] = r.data[:data]
        end

        r = validate_ddb_options(params)
        return r unless r.success?

        success_with_data(data: params)
      end



      def validate_ddb_options(params)
        params.each do |option, value|
          if self.class.ddb_options.keys.include?(option)
            unless self.class.ddb_options[option].include?(value)
              return error_with_identifier("invalid_ddb_option", "")
            end
          end
        end
        return error_with_identifier("invalid_ddb_option", "") if (params[:limit].present? && !params[:limit].is_a?(Numeric))

        # Note: index_name should always be validated before is_valid_exclusive_start_key?
        return error_with_identifier("invalid_ddb_option", "") unless is_valid_index_name?(params[:index_name])

        return error_with_identifier("invalid_ddb_option", "") unless is_valid_exclusive_start_key?(params[:exclusive_start_key], params[:index_name])
        success
      end

      # check if index name is valid
      # * Author: MAYUR
      # * Date: 26/02/2019
      # * Reviewed By:
      #
      # @param [String] index_name (mandatory)
      # @return [Bool]
      #
      def is_valid_index_name?(index_name)
        index_name.blank? || table_info[:indexes].keys.include?(index_name)
      end

      # check if exclusive start key is valid
      # * Author: MAYUR
      # * Date: 26/02/2019
      # * Reviewed By:
      #
      # @param [Hash] key (mandatory)
      # @param [String] index_name (mandatory)
      # @return [Bool]
      #
      def is_valid_exclusive_start_key?(key, index_name)
        return true if key.blank?

        if index_name.present?
          return  (key.keys - table_info[:indexes][index_name].values).blank?
        end
       (key.keys - [table_info[:partition_key], table_info[:sort_key]]).blank?
      end

      # map list of long names to single short name
      # operations done: [validate, merge columns, long to short]
      # used for - remove, projection_expression
      #
      # * Author: MAYUR
      # * Date: 01/02/2019
      # * Reviewed By:
      #
      # @param [Array] list (mandatory) - if full names -> list of list | if short names -> list of strings
      # @return [Result::Base] - list of short names
      #
      def map_list_to_be_name(list)
        return error_with_identifier('mandatory_params_missing',
                                     'd_t_mltbn_1') unless list

        result_list = []

        list.each do |item|
          if use_column_mapping?
            item = item.map {|x| x.to_sym}
            short_name = self.class.long_to_short_name_mapping[item.to_s]
            return error_with_identifier('extra_item_param_given',
                                         'sb_1',
                                         []
            ) if short_name.blank?

            result_list << short_name
          else
            return error_with_identifier('extra_item_param_given',
                                         'sb_2',
                                         []
            ) if table_info[:merged_columns][item].blank?
            result_list << item
          end
        end
        success_with_data(data: result_list)
      end


      # validate and map params, convert variables in ddb format i.e. 1 -> {:n => "1"}
      # also if full names are used then they are converted to short names and
      # values are also joined by delimiter.
      # operations done: [validate, merge columns, long to short, value processed to ddb format]
      #
      # * Author: MAYUR
      # * Date: 01/02/2019
      # * Reviewed By:
      #
      # @param [Array] item_list (mandatory)
      # @return [Result::Base]
      #
      def validate_and_map_params(item_list)
        return error_with_identifier('mandatory_params_missing',
                                     'd_t_vamp_1') unless item_list

        formatted_item_list = []
        if use_column_mapping?
          item_list.each do |item|
            dup_item = item.dup
            item_attr = item[:attribute]
            enum_converted_item_attr = convert_enum_values(item_attr)
            r  = convert_long_to_short_name(enum_converted_item_attr)
            return r unless r.success?

            hash_with_be_name = r.data[:data]
            dup_item[:attribute] = hash_with_be_name
            formatted_item_list << dup_item
          end
        else
          r = validate_short_names(item_list)
          return r unless r.success?
          formatted_item_list = item_list
        end
        success_with_data(data: convert_to_ddb_format(formatted_item_list))
      end



      def validate_short_names(item_list)
        item_list.each do |item|
          return error_with_identifier('extra_params_given',
                                       'd_t_vsn_1') if (item[:attribute].keys - table_info[:merged_columns].deep_symbolize_keys.keys).present?
        end
        success
      end



      # convert enum values
      #
      # * Author: MAYUR
      # * Date: 01/02/2019
      # * Reviewed By:
      #
      # @param [Array] item_attr (mandatory)
      # @return [Hash]
      #
      def convert_enum_values(item_attr)
        enum_converted_item_attr = {}
        item_attr.each do |item_key, item_value|
          if self.class.enum[item_key].present?
            enum_converted_item_attr[item_key] = self.class.enum[item_key][item_value]
          else
            enum_converted_item_attr[item_key] = item_value
          end
        end
        enum_converted_item_attr
      end


      def convert_to_ddb_format(short_name_array_list)
        result_arr = []
        short_name_array_list.each do |item|
          item_attr = item[:attribute].keys[0]
          item_attr_val = item[:attribute].values[0]
          column_info = table_info[:merged_columns][item_attr]
          if column_info[:keys].length > 1
            item[:attribute][item_attr] = {GlobalConstant::Aws::Ddb::Base.ddb_variable_type[:string] => item_attr_val.to_s}
          elsif data_type_array_hash.include?(column_info[:keys][0][:type])
            item[:attribute][item_attr] = {GlobalConstant::Aws::Ddb::Base.ddb_variable_type[:string] => item_attr_val.to_json}
          else
            item[:attribute][item_attr] = {column_info[:keys][0][:type] => item_attr_val.to_s}
          end
          result_arr << item
        end
        result_arr
      end

      def convert_long_to_short_name(hash)
        hash_with_be_name = {}
        short_attr_name = self.class.long_to_short_name_mapping[hash.keys.to_s]
        return error_with_identifier('extra_item_param_given',
                                     'sb_1',
                                     []
        ) if short_attr_name.blank?

        hash_with_be_name[short_attr_name] = merge_column_values(hash)
        success_with_data(data: hash_with_be_name)
      end

      # map merged columns , merged_columns -> one short name belongs to multiple lone names
      #
      # * Author: MAYUR
      # * Date: 01/02/2019
      # * Reviewed By:
      #
      # @param [Hash] item_attr (mandatory)
      # @return [string]
      #
      def merge_column_values(item_attr)
         item_attr_values = item_attr.values
         item_attr_values.length > 1 ? item_attr.values.join(table_info[:delimiter]) : item_attr.values[0]
      end

      #ddb data types array hash,
      #
      # * Author: MAYUR
      # * Date: 01/02/2019
      # * Reviewed By:
      #
      #
      # @return [Array]
      #
      def data_type_array_hash
        [GlobalConstant::Aws::Ddb::Base.variable_type[:array],
         GlobalConstant::Aws::Ddb::Base.variable_type[:hash]]
      end

      # parses response array if
      #
      # * Author: mayur
      # * Date: 01/02/2019
      # * Reviewed By:
      #
      # @param item_list [Array] (mandatory)
      # @return [Array]
      #
      def parse_response_array(item_list)
        items = []
        item_list.each do |item|
          items << parse_response(item)
        end
        items
      end

      # parses response i.e. convert backend mames to long names
      #
      # * Author: mayur
      # * Date: 01/02/2019
      # * Reviewed By:
      #
      # @param r [Hash] (mandatory)
      # @return [Hash]
      #
      def parse_response(r)
        return r unless r.present?
        merged_col, separate_col = {}, {}
        data_type_string = GlobalConstant::Aws::Ddb::Base.ddb_variable_type[:string]
        if use_column_mapping?
          r.each do |key, val|
            merged_columns = table_info[:merged_columns][key][:keys]
            if merged_columns.length > 1
              val = val[data_type_string].split(table_info[:delimiter])
              merged_columns.each_with_index do |long_name_hash, index|
                merged_col[long_name_hash[:name]] = {long_name_hash[:type] => val[index]}
              end
            else
              separate_col[merged_columns[0][:name]] = val
            end
          end
          # Note: merge merged_col afterwards to give preference to separate_col
          normalize_response(separate_col.merge(merged_col))
        else
          normalize_response r
        end
      end

      #
      # normalizes response i.e.
      #
      # * Author: mayur
      # * Date: 01/02/2019
      # * Reviewed By:
      #
      # @param hash [] (mandatory)
      # @return [Hash]
      #
      def normalize_response(hash)
        result_hash = {}
        hash.each do |k, v|
          result_hash[k] = format_value(v.to_hash, k)
        end if hash.present?
        result_hash
      end

      #
      # format value
      #
      # * Author: mayur
      # * Date: 01/02/2019
      # * Reviewed By:
      #
      # @param value [] (mandatory)
      # @return field_name [string]
      #
      def format_value(value, field_name = '')
        if self.class.enum[field_name].present?
          return self.class.enum[field_name].key(value.first[1].to_i)
        elsif value.first[0] == GlobalConstant::Aws::Ddb::Base.ddb_variable_type[:string]
          return parse_json value.first[1]
        elsif value.first[0] == GlobalConstant::Aws::Ddb::Base.ddb_variable_type[:number]
          return value.first[1].to_i
        else
          throw "Invalid data type from DDB"
        end
      end


      def parse_json(string)
        JSON.parse(string) rescue string
      end

      # format last evaluated key
      #
      # * Author: mayur
      # * Date: 01/02/2019
      # * Reviewed By:
      #
      # @param last_eval_key [Hash] (mandatory)
      #
      def format_last_eval_key(last_eval_key)
        return nil if last_eval_key.blank?
        last_evaluated_key = {}
        last_eval_key.each do |k, v|
          last_evaluated_key[k] = v.to_hash
        end
        last_evaluated_key
      end


    end

    class_methods do

      # sets table info
      #
      # * Author: mayur
      # * Date: 01/02/2019
      # * Reviewed By:
      #
      # @param table_info [Hash] (mandatory)
      #
      #
      def table (table_info)
        puts "----table_info--- #{table_info}"
        self.table_info = table_info.with_indifferent_access

      end

      # returns raw table name
      #
      # * Author: mayur
      # * Date: 01/02/2019
      # * Reviewed By:
      #
      def raw_table_name
        self.table_info[:raw_name]
      end

      # get short key name from long name
      #
      # * Author: mayur
      # * Date: 01/02/2019
      # * Reviewed By:
      #
      # @param condition [Array] (mandatory)
      # @return [Hash]
      #
      def long_to_short_name_mapping
        return @long_to_short_name_mapping if @long_to_short_name_mapping.present?
        @long_to_short_name_mapping = {}
        self.table_info[:merged_columns].each do |short_name, col_info|
          @long_to_short_name_mapping[col_info[:keys].map {|k| k[:name]}.to_s] = short_name
        end
        @long_to_short_name_mapping
      end

      def allowed_params
        GlobalConstant::Aws::Ddb::Base.allowed_params
      end

      def ddb_options
        GlobalConstant::Aws::Ddb::Base.ddb_options
      end

    end

  end
end
