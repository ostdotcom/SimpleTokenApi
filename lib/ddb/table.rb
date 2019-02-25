module Ddb
  module Table
    extend ActiveSupport::Concern

    include Util::ResultHelper

    include JSON

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
      # # attributes in response can be accessed as *r.data[:data][:attributes]*

      # todo:ddb: - item -> params
      def put_item(item)

        r = validate_for_ddb_options(item, self.class.allowed_params[:put_item])
        return r unless r.success?
        # todo:ddb - use param_mapping function
        r = validate_and_map_params(item[:item])
        return r unless r.success?

        item[:item] = r.data[:data]

        r = Ddb::QueryBuilder::PutItem.new({params: item, table_info: table_info}).perform
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

      def delete_item(item)
        r = validate_for_ddb_options(item, self.class.allowed_params[:delete_item])
        return r unless r.success?

        r = validate_and_map_params(item[:key])
        return r unless r.success?

        item[:key] = r.data[:data]

        r = Ddb::QueryBuilder::DeleteItem.new({params: item, table_info: table_info}).perform

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
      def update_item(item)

        r = validate_for_ddb_options(item, self.class.allowed_params[:update_item])
        return r unless r.success?

        r = update_params_mapping(item)
        return r unless r.success?

        item = r.data[:data]

        r = Ddb::QueryBuilder::UpdateItem.new({params: item, table_info: table_info}).perform

        return r unless r.success?

        ddb_r = Ddb::Api::UpdateItem.new(params: r.data).perform

        ddb_r unless ddb_r.success?

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
      def scan(query = {})

        r = validate_for_ddb_options(query, self.class.allowed_params[:scan])
        return r unless r.success?

        r = query_params_mapping(query)
        return r unless r.success?

        query = r.data[:data]

        r = Ddb::QueryBuilder::Scan.new({params: query, table_info: table_info}).perform
        return r unless r.success?

        ddb_r = Ddb::Api::Scan.new(params: r.data).perform

        return ddb_r unless (ddb_r.success? && ddb_r.data[:data][:items].present?)

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

      def query(query)
        r = validate_for_ddb_options(query, self.class.allowed_params[:query])
        return r unless r.success?

        r = query_params_mapping(query)
        return r unless r.success?

        query = r.data[:data]
        r = Ddb::QueryBuilder::Query.new({params: query, table_info: table_info}).perform
        return r unless r.success?
        ddb_r = Ddb::Api::Query.new(params: r.data).perform
        return ddb_r unless (ddb_r.success? && ddb_r.data[:data][:items].present?)

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

      def get_item(item)
        r = validate_for_ddb_options(item, self.class.allowed_params[:get_item])
        return r unless r.success?

        r = validate_and_map_params(item[:key])
        return r unless r.success?
        item[:key] = r.data[:data]

        if item[:projection_expression].present?
          r = map_list_to_be_name item[:projection_expression]
          return r unless r.success?
          item[:projection_expression] = r.data[:data]
        end

        r = Ddb::QueryBuilder::GetItem.new({params: item, table_info: table_info}).perform
        return r unless r.success?
        ddb_r = Ddb::Api::GetItem.new(params: r.data).perform
        return ddb_r unless (ddb_r.success? && ddb_r.data[:data][:item].present?)

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
      def batch_write(items)
        items_list, resp_list, instance_array = [], [], []
        r = validate_for_ddb_options(items, self.class.allowed_params[:batch_write])
        cnt = 0
        return r unless r.success?
        items[:items].each do |item|
          r = validate_and_map_params(item)
          return r unless r.success?
          items_list << r.data[:data]
        end

        r = Ddb::QueryBuilder::BatchWrite.new({params: {items: items_list}, table_info: table_info}).perform

        ddb_r = Ddb::Api::BatchWrite.new(params: r.data).perform

        list = ddb_r.data[:data]
        return success if list.blank?
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
        # todo:ddb: - if key present then value should be present
        mandatory_params = params[:mandatory]
        optional_params = params[:optional]
        return error_with_identifier('mandatory_params_missing',
                                     'sb_1',
                                     (mandatory_params - item.keys)
        ) if (mandatory_params - item.keys).present?

        # todo:ddb: - unexpected_params_present
        return error_with_identifier('unexpected_params_present',
                                     'sb_1',
                                     (item.keys - (optional_params + mandatory_params))
        ) if (item.keys - (mandatory_params + optional_params)).present?
        success
      end


      # mapping (i.e. full name -> short name conversion ) for update function
      #
      # * Author: MAYUR
      # * Date: 01/02/2019
      # * Reviewed By:
      #
      # @param item [Hash] (mandatory)
      # @return [Result Base]
      #
      def update_params_mapping(item)
        # todo:ddb - use from all methods. validate all keys.
        remove_list = []
        [:key, :set, :add].each do |operation|
          r = validate_and_map_params(item[operation])
          return r unless r.success?
          item[operation] = r.data[:data]
        end
        r = map_list_to_be_name(item[:remove])
        return r unless r.success?
        item[:remove] = r.data[:data]

        success_with_data(data: item)
      end

      # map list of long names to single short name
      #
      # * Author: MAYUR
      # * Date: 01/02/2019
      # * Reviewed By:
      #
      # @param [Array] list (mandatory) - if full names -> list of list | if short names -> list of strings
      # @return [Result::Base] - list of short names
      #
      def map_list_to_be_name(list)
        result_list = []

        list.each do |item|
          if use_column_mapping?
            short_name = get_short_key_name(item)
            # todo:ddb - extra_item_param_given not defined
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


      # mapping (i.e. full name -> short name conversion ) for query, scan function
      #
      # * Author: MAYUR
      # * Date: 01/02/2019
      # * Reviewed By:
      #
      # @param query [Hash] (mandatory)
      # @return [Result Base]
      #
      def query_params_mapping(query)
        updated_query = query.dup
        if updated_query[:key_conditions].present?
          r = validate_and_map_params updated_query[:key_conditions]
          return r unless r.success?
          updated_query[:key_conditions] = r.data[:data]
        end

        if updated_query[:filter_conditions].present?
          r = validate_and_map_params updated_query[:filter_conditions][:conditions]
          return r unless r.success?
          updated_query[:filter_conditions][:conditions] = r.data[:data]

        end
        if updated_query[:projection_expression].present?
          r = map_list_to_be_name updated_query[:projection_expression]
          return r unless r.success?
          updated_query[:projection_expression] = r.data[:data]
        end

        success_with_data(data: updated_query)

      end


      # validate and map params, convert variables in ddb format i.e. 1 -> {:n => "1"}
      # also if full names are used then they are converted to short names and
      # values are also joined by delimiter.
      #
      # * Author: MAYUR
      # * Date: 01/02/2019
      # * Reviewed By:
      #
      # @param [Array] item_list (mandatory)
      # @return [Result::Base]
      #
      def validate_and_map_params(item_list)
        # todo:ddb: - return error when values missing
        return success unless item_list
        # todo:ddb: - for use_column_mapping? do operations and then common function for validate_map_without_default_mapping
        # enum val update
        # full name processing
        # merge values
        # use values as per ddb format
        if use_column_mapping?
          return validate_map_with_default_mapping item_list
        else
          return validate_map_without_default_mapping item_list
        end
      end

      # if full names are used then validate and map params,
      # convert variables in ddb format and names are converted in short names
      #
      # * Author: MAYUR
      # * Date: 01/02/2019
      # * Reviewed By:
      #
      # @param [Array] item_list (mandatory)
      # @return [Result::Base]
      #
      def validate_map_with_default_mapping (item_list)

        temp_item_list = []
        item_list.each do |item|
          attr = {}
          item_attr = item[:attribute]
          short_attr_name = get_short_key_name(item_attr.keys)
          return error_with_identifier('extra_item_param_given',
                                       'sb_1',
                                       []
          ) if short_attr_name.blank?

          # todo:ddb - merge logic for map_non_merged_columns and map_merged_columns and use 1 function
          if item_attr.values.length > 1
            attr[short_attr_name] = {GlobalConstant::Aws::Ddb::Base.variable_type[:string] => map_merged_columns(item_attr).to_s}
          else
            attr[short_attr_name] = map_non_merged_columns(table_info[:merged_columns][short_attr_name][:keys][0][:type],
                                                           item_attr.values[0], item_attr.keys[0])
          end

          temp_item_list << {attribute: attr}
        end
        return success_with_data(data: temp_item_list)
      end

      # if short names are used then validate and map params,
      # convert variables in ddb format
      #
      # * Author: MAYUR
      # * Date: 01/02/2019
      # * Reviewed By:
      #
      # @param [Array] item_list (mandatory)
      # @return [Result::Base]
      #
      def validate_map_without_default_mapping(item_list)
        temp_item_list = []
        item_list.each do |item|
          column_info = table_info[:merged_columns][item[:attribute].keys[0]]
          return error_with_identifier('extra_item_param_given',
                                       'sb_4',
                                       []
          ) if column_info.blank?
          attr = {}
          item_attr = item[:attribute]
          if column_info[:keys].length > 1
            merged_cols = map_merged_columns( Hash[column_info[:keys].map{|k| k[:name]}
                                                       .zip(item_attr.values[0]
                                                                .split(table_info[:delimiter]))])
            attr[item_attr.keys[0]] = {GlobalConstant::Aws::Ddb::Base.variable_type[:string] => merged_cols.to_s}
          else
            attr[item_attr.keys[0]] = map_non_merged_columns(column_info[:keys][0][:type],
                                                             item_attr.values[0], column_info[:keys][0][:name])
          end
          item[:attribute] = attr
          temp_item_list << item
        end
        return success_with_data(data: temp_item_list)
      end


      # map non merged columns , non_merged_columns -> one short name belongs to one lone name
      #
      # * Author: MAYUR
      # * Date: 01/02/2019
      # * Reviewed By:
      #
      # @param [string] data_type (mandatory)
      # @param [string] val (mandatory)
      # # @param [string] long_name (mandatory)
      # @return [Hash]
      #
      def map_non_merged_columns(data_type, val, long_name)
        # todo:ddb: - why is array, HAsh not saved by its type but string
        if data_type_array_hash.include?(data_type)
          return {GlobalConstant::Aws::Ddb::Base.variable_type[:string] => val.to_json}
          # todo:ddb: - enum should not be a type
        elsif data_type == GlobalConstant::Aws::Ddb::Base.variable_type[:enum]
          return {GlobalConstant::Aws::Ddb::Base.variable_type[:number] =>
                      self.class.enum[long_name][val].to_s}
        else
          return {data_type => val.to_s}
        end
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
      def map_merged_columns(item_attr)
        attribute_values = []
        item_attr.each do |key, value|
          if self.class.enum[key].present?
            attribute_values << self.class.enum[key][value]
          else
            attribute_values << value
          end
        end
        attribute_values.join(table_info[:delimiter])
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
        data_type_string = GlobalConstant::Aws::Ddb::Base.variable_type[:string]
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
          normalize_response separate_col.merge(merged_col)
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
        # todo:ddb: - use enum processing if use col mapping
        if (!use_column_mapping?) && is_any_key_enum?(field_name)
          return replace_enum_names(field_name, value.first[1])
        elsif value.first[0] == GlobalConstant::Aws::Ddb::Base.variable_type[:string]
          return parse_json value.first[1]
        elsif value.first[0] == GlobalConstant::Aws::Ddb::Base.variable_type[:number]
          return value.first[1].to_i
        elsif value.first[0] == GlobalConstant::Aws::Ddb::Base.variable_type[:enum]
          return self.class.enum[field_name].key(value.first[1].to_i)
        else
          # todo:ddb - throw an error
          return value.first[1]
        end
      end

      #
      # replace enums integers by names
      #
      # * Author: mayur
      # * Date: 01/02/2019
      # * Reviewed By:
      #
      # @param field_name [] (mandatory)
      # @return [string]
      #
      def replace_enum_names(field_name, field_value)
        fields = field_value.split(table_info[:delimiter])
        result_field = []
        fields.each_with_index do |val, index|
          if self.class.enum[long_column_names(field_name)[index]].present?
            result_field << self.class.enum[long_column_names(field_name)[index]].key(val.to_i)
          else
            result_field << val
          end
        end
        result_field.join(table_info[:delimiter])
      end


      #
      # check if any of the key in
      #
      # * Author: mayur
      # * Date: 01/02/2019
      # * Reviewed By:
      #
      # @param field_name [] (mandatory)
      # @return [string]
      #
      def is_any_key_enum?(field_name)
        (long_column_names(field_name) & self.class.enum.keys).present?
      end

      def long_column_names(field_name)
        table_info[:merged_columns][field_name][:keys].map {|k| k[:name].to_s}
      end

      def parse_json(string)
        JSON.parse(string) rescue string
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
      def get_short_key_name(condition)
        # todo:ddb: - recheck
        table_info[:merged_columns].
            select {
                |_, v|
              a = v[:keys].map {|k| k[:name]}
              a.sort == condition.sort
            }.keys.first
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
        self.table_info = table_info
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

      def allowed_params
        GlobalConstant::Aws::Ddb::Base.allowed_params
      end

    end

  end
end
