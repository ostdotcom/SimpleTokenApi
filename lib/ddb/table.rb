module Ddb


  module Table
    extend ActiveSupport::Concern

    include Util::ResultHelper

    included do
      cattr_accessor :table_info

      def self.allowed_params
        GlobalConstant::Aws::Ddb::Config.allowed_params
      end


      # Query on dynamodb
      #
      # * Author: MAYUR
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
        instance_array = []
        r = validate_for_ddb_options(query, self.class.allowed_params[:query])
        return r unless r.success?

        r = query_params_mapping(query)
        return r unless r.success?

        query = r.data[:data]
        r = Ddb::QueryBuilder::Query.new({params: query, table_info: table_info}).perform
        return r unless r.success?
        ddb_r = Ddb::Api::Query.new(params: r.data).perform
        return ddb_r unless (ddb_r.success? && ddb_r.data[:data][:items].present?)

        parsed_resp = parse_response_array(ddb_r.data[:data][:items])

        last_evaluated_key = format_last_eval_key ddb_r.data[:data][:last_evaluated_key]

        parsed_resp.each do |resp|
          instance_array << self.class.new(@params, @options).initialize_instance_variables(resp)
        end
        success_with_data(data: {items: instance_array, last_evaluated_key: last_evaluated_key})
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

        attributes = parse_response(ddb_r.data[:data][:attributes])

        success_with_data(data: {attributes: initialize_instance_variables(attributes)})
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

        if item[:projection_expression].present?
          r = map_list_to_be_name item[:projection_expression]
          return r unless r.success?
          item[:projection_expression] = r.data[:data]
        end


        return r unless r.success?
        item[:key] = r.data[:data]
        r = Ddb::QueryBuilder::GetItem.new({params: item, table_info: table_info}).perform
        return r unless r.success?
        ddb_r = Ddb::Api::GetItem.new(params: r.data).perform

        resp_item = (ddb_r.data[:data] || {})[:item]

        return ddb_r unless (ddb_r.success? && resp_item.present?)

        resp_item = parse_response(resp_item)

        success_with_data(data: {item: initialize_instance_variables(resp_item)})

      end

      def normalize_response(hash)
        data_type_array_hash = [ GlobalConstant::Aws::Ddb::Config.variable_types[:array],
                                 GlobalConstant::Aws::Ddb::Config.variable_types[:hash]]
        result_hash = {}
        hash.each do |k, v|
          val = data_type_array_hash.include?(k['type']) ? format_value(v[k['type']]) :
                    convert_var_to_correct_format(v[k['type']], k['type'])
          result_hash[k['name']] = val
        end if hash.present?
        result_hash
      end


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
      #
      def put_item(item)

        r = validate_for_ddb_options(item, self.class.allowed_params[:put_item])
        return r unless r.success?

        r = validate_and_map_params(item[:item])

        return r unless r.success?
        item[:item] = r.data[:data]

        r = Ddb::QueryBuilder::PutItem.new({params: item, table_info: table_info}).perform

        return r unless r.success?

        ddb_r = Ddb::Api::PutItem.new(params: r.data).perform

        return ddb_r unless ddb_r.success?

        attributes = parse_response(ddb_r.data[:data][:attributes])

        success_with_data(data: {attributes: initialize_instance_variables(attributes)})
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

        instance_array = []

        r = validate_for_ddb_options(query, self.class.allowed_params[:scan])
        return r unless r.success?

        r = query_params_mapping(query)
        return r unless r.success?

        query = r.data[:data]

        r = Ddb::QueryBuilder::Scan.new({params: query, table_info: table_info}).perform
        return r unless r.success?
        ddb_r = Ddb::Api::Scan.new(params: r.data).perform

        return ddb_r unless (ddb_r.success? && ddb_r.data[:data][:items].present?)

        parsed_resp = parse_response_array(ddb_r.data[:data][:items])

        last_evaluated_key = format_last_eval_key ddb_r.data[:data][:last_evaluated_key]

        parsed_resp.each do |resp|
          instance_array << self.class.new(@params, @options).initialize_instance_variables(resp)
        end

        success_with_data(data: {items: instance_array, last_evaluated_key: last_evaluated_key})

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

        attributes = parse_response(ddb_r.data[:data][:attributes])

        success_with_data(data: {attributes: initialize_instance_variables(attributes)})
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

        list = ddb_r.data[:data][:unprocessed_items][table_info[:name].to_s]
        list.each do |l|
          resp_list << parse_response(l["put_request"]["item"])
        end if list.present?
        return success if list.blank?
        resp_list.each do |resp|
          instance_array << self.class.new(@params, @options).initialize_instance_variables(resp)
        end
        error_with_identifier('unprocessed_entities',
                              'sb_1',
                              [],
                              '',
                              {unprocessed: resp_list}
        )
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
                                     'sb_1',
                                     (mandatory_params - item.keys)
        ) if (mandatory_params - item.keys).present?

        return error_with_identifier('unexpected_params_present',
                                     'sb_1',
                                     (item.keys - (optional_params + mandatory_params))
        ) if (item.keys - (mandatory_params + optional_params)).present?
        success
      end

      def format_value(value)
        data_type_array_hash = [ GlobalConstant::Aws::Ddb::Config.variable_types[:array],
                                 GlobalConstant::Aws::Ddb::Config.variable_types[:hash]]
        if value.class == Hash
          result_obj = {}
          value.each do |param, type|
            type_of_var = type.to_hash.keys[0]
            value_of_var = type.to_hash.values[0]
            result_obj[param] = data_type_array_hash.include?(type_of_var) ? format_value(value_of_var) :
                                    convert_var_to_correct_format(value_of_var, type_of_var)
          end
        elsif value.class == Array
          result_obj = []
          value.each do |type|
            type_of_var = type.to_hash.keys[0]
            value_of_var = type.to_hash.values[0]
            result_obj << data_type_array_hash.include?(type_of_var) ? format_value(value_of_var) :
                convert_var_to_correct_format(value_of_var, type_of_var)
          end
        else
          return value
        end
        result_obj
      end

      def convert_var_to_correct_format(value_of_var, type_of_var)
        if type_of_var ==  GlobalConstant::Aws::Ddb::Config.variable_types[:number]
          return value_of_var.to_i
        end
        value_of_var
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

      def map_list_to_be_name(list)
        result_list = []

        list.each do |remove_item|
          if use_column_mapping?
            short_name = get_short_key_name(remove_item)
            return error_with_identifier('extra_item_param_given',
                                         'sb_1',
                                         []
            ) if short_name.blank?
            result_list << short_name
          else
            return error_with_identifier('extra_item_param_given',
                                         'sb_1',
                                         []
            ) if table_info[:merged_columns][remove_item].blank?
            result_list << remove_item
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

      # params mapping mapping (i.e. full name -> short name conversion ) for query, scan function
      #
      # * Author: MAYUR
      # * Date: 01/02/2019
      # * Reviewed By:
      #
      # @param query [Hash] (mandatory)
      # @return [Result Base]
      #
      def validate_and_map_params(item_list)
        temp_item_list = []
        return success unless item_list
        if use_column_mapping?
          item_list.each do |item|

            attr = {}
            item_attr = item[:attribute]
            short_attr_name = get_short_key_name(item_attr.keys)
            return error_with_identifier('extra_item_param_given',
                                         'sb_1',
                                         []
            ) if short_attr_name.blank?
            attr[short_attr_name] = item_attr.values.length > 1 ?
                                        {s: item_attr.values.join(table_info[:delimiter])} :
                                        {table_info[:merged_columns][short_attr_name][:keys][0][:type] => item_attr.values[0].to_s}
            item[:attribute] = attr
            temp_item_list << item
          end
          return success_with_data(data: temp_item_list)
        else
          item_list.each do |item|
            return error_with_identifier('extra_item_param_given',
                                         'sb_1',
                                         []
            ) if table_info[:merged_columns][item[:attribute].keys[0]].blank?
          end
          return success_with_data(data: item_list)
        end
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
        data_type_string = GlobalConstant::Aws::Ddb::Config.variable_types[:string]
        if use_column_mapping?
          r.each do |key, val|
            merged_columns = table_info[:merged_columns][key][:keys]
            if merged_columns.length > 1
              val = val[data_type_string].split(table_info[:delimiter])
              merged_columns.each_with_index do |long_name, index|
                merged_col[long_name[:name]] = {long_name[:type] => val[index]}
              end
            else
              separate_col[merged_columns[0]] = val
            end
          end
          normalize_response separate_col.merge(merged_col)
        else
          normalize_response r
        end
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
        last_eval_key.each do |k,v|
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

    end

  end
end
