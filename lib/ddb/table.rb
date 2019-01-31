module Ddb
  module Table
    extend ActiveSupport::Concern

    include Util::ResultHelper

    included do
      cattr_accessor :table_info


      def query(query)
        @mandatory_options = [:key_conditions]
        @optional_options = [:filter_conditions, :consistent_read, :exclusive_start_key,
                             :return_consumed_capacity, :limit, :projection_expression, :index_name]

        r = validate_for_ddb_options query
        return r unless r.success?

        r = validate_item query[:key_conditions]
        return r unless r.success?
        if query[:filter_conditions].present?
          r = validate_item query[:filter_conditions][:conditions]
          return r unless r.success?
        end

        query = use_column_mapping? ? query_params_mapping(query) : query


        r = Ddb::QueryBuilder::Query.new({params: query, table_info: table_info}).perform
        return r unless r.success?
        ddb_r = Ddb::Api::Query.new(params: r.data, retry_count: 3).perform
        return ddb_r unless ddb_r.success?

        parsed_resp = parse_response_array(ddb_r.data[:data][:items])
        success_with_data(data: parsed_resp)
      end


      def delete_item(item)
        @mandatory_options = [:key]

        @optional_options = [:return_item_collection_metrics, :return_consumed_capacity, :return_values]

        r = validate_for_ddb_options item
        return r unless r.success?

        r = validate_item item[:key]
        return r unless r.success?

        item[:key] = use_column_mapping? ? params_mapping(item[:key]) : item[:key]

        r = Ddb::QueryBuilder::DeleteItem.new({params: item, table_info: table_info}).perform

        return r unless r.success?
        ddb_r = Ddb::Api::DeleteItem.new(params: r.data, retry_count: 3).perform
        return ddb_r unless ddb_r.success?


        attributes = use_column_mapping? && ddb_r.data[:data][:attributes].present? ?
                         parse_response(ddb_r.data[:data][:attributes]) : ddb_r.data[:data][:attributes]

        success_with_data(data: attributes)
      end


      def get_item(item)

        @mandatory_options = [:key]

        @optional_options = [:projection_expression, :consistent_read, :return_consumed_capacity]


        r = validate_for_ddb_options item
        return r unless r.success?

        r = validate_item item[:key]
        return r unless r.success?

        item[:key] = use_column_mapping? ? params_mapping(item[:key]) : item[:key]

        r = Ddb::QueryBuilder::GetItem.new({params: item, table_info: table_info}).perform

        return r unless r.success?
        ddb_r = Ddb::Api::GetItem.new(params: r.data, retry_count: 3).perform
        return ddb_r unless ddb_r.success?

        ddb_r = ddb_r.data[:data]

        ddb_r[:item] = use_column_mapping? && ddb_r[:item].present? ? parse_response(ddb_r[:item]) : ddb_r[:item]

        success_with_data(data: ddb_r[:item])

      end


      def put_item(item)


        @mandatory_options = [:item]

        @optional_options = [:return_item_collection_metrics, :return_consumed_capacity, :return_values]


        r = validate_for_ddb_options item
        return r unless r.success?

        r = validate_item item[:item]
        return r unless r.success?


        item[:item] = use_column_mapping? ? params_mapping(item[:item]) : item[:item]
        r = Ddb::QueryBuilder::PutItem.new({params: item, table_info: table_info}).perform

        return r unless r.success?

        ddb_r = Ddb::Api::PutItem.new(params: r.data, retry_count: 3).perform


        attributes = use_column_mapping? && ddb_r.data[:data][:attributes].present? ?
                         parse_response(ddb_r.data[:data][:attributes]) : ddb_r.data[:data][:attributes]

        ddb_r unless ddb_r.success?
        success_with_data(data: attributes)
      end


      def scan(query = {})

        @mandatory_options = []

        @optional_options = [:filter_conditions, :index_name, :consistent_read, :exclusive_start_key,
                             :return_consumed_capacity, :limit, :projection_expression]


        r = validate_for_ddb_options query
        return r unless r.success?

        query = use_column_mapping? ? query_params_mapping(query) : query

        r = Ddb::QueryBuilder::Scan.new({params: query, table_info: table_info}).perform
        return r unless r.success?
        ddb_r = Ddb::Api::Scan.new(params: r.data, retry_count: 3).perform
        return ddb_r unless ddb_r.success?
        parsed_resp = parse_response_array(ddb_r.data[:data][:items])
        success_with_data(data: parsed_resp)

      end

      def update_item(item)

        @mandatory_options = [:key]

        @optional_options = [ :set, :add, :remove, :return_consumed_capacity, :return_item_collection_metrics, :return_values ]

        r = validate_for_ddb_options item
        return r unless r.success?


        r = validate_item item[:key]
        return r unless r.success?


        item = update_params_mapping(item)

        r = Ddb::QueryBuilder::UpdateItem.new({params: item, table_info: table_info}).perform

        return r unless r.success?


        ddb_r = Ddb::Api::UpdateItem.new(params: r.data, retry_count: 3).perform
        ddb_r unless ddb_r.success?
        success_with_data(data: ddb_r)
      end



      def validate_item(item_list)

          item_list.each do |item|

            return error_with_identifier('extra_item_param_given',
                                         'sb_1',
                                         []
            ) if (get_short_key_name(item[:attribute].keys).blank? && use_column_mapping?) &&
                table_info[:merged_columns][item[:attribute].keys[0]].blank?
          end

        success
      end

      def validate_for_ddb_options(item)
        return error_with_identifier('mandatory_params_missing',
                                     'sb_1',
                                     (@mandatory_options - item.keys)
        ) if (@mandatory_options - item.keys).present?

        return error_with_identifier('unexpected_params_present',
                                     'sb_1',
                                     (item.keys - (@optional_options + @mandatory_options))
        ) if (item.keys - (@optional_options + @mandatory_options)).present?
        success
      end


      def batch_write(items)


        @mandatory_options = [:items]
        @optional_options = []
        items_list = []
        r = validate_for_ddb_options items
        cnt = 0
        return r unless r.success?
        items[:items].each do |item|
          r = validate_item item
          return r unless r.success?
          items_list << params_mapping(item)
        end

        r = Ddb::QueryBuilder::BatchWrite.new({params: {items: items_list}, table_info: table_info}).perform

        ddb_r = Ddb::Api::BatchWrite.new(params: r.data, retry_count: 3).perform
        puts ddb_r.inspect
        success
      end





      def update_params_mapping(item)
        # merge columns
        return item unless use_column_mapping?

        remove_list = []
        [:key, :set, :add].each do |operation|
          item[operation] = params_mapping(item[operation])
        end
        item[:remove].each do |remove_item|
          remove_list << get_short_key_name(remove_item)
        end if item[:remove].present?
        item[:remove] = remove_list
        item
      end

      def query_params_mapping(query)
        updated_query = query.dup

        updated_query[:key_conditions] = params_mapping updated_query[:key_conditions] if updated_query[:key_conditions].present?
        updated_query[:filter_conditions][:conditions] =
            params_mapping updated_query[:filter_conditions][:conditions] if updated_query[:filter_conditions].present?

        updated_query
      end

      def params_mapping(item_list_i)
        item_list = [] # item_list.dup
        item_list_i.each do |item|

          attr = {}
          item_attr = item[:attribute]
          attr[get_short_key_name(item_attr.keys)] = item_attr.values.length > 1 ?
                                                         item_attr.values.join(table_info[:delimiter]) : item_attr.values[0]
          item[:attribute] = attr
          item_list << item
        end
        item_list
      end




      def parse_response_array(item_list)
        items = []
        item_list.each do |item|
          items << parse_response(item)
        end
        items
      end

      # need to refactor this
      def parse_response(r)
        merged_col, separate_col = {}, {}

        r.each do |key, val|
          merged_columns = table_info[:merged_columns][key][:keys]
          if merged_columns.length > 1
            val = val.split(table_info[:delimiter])
            merged_columns.each_with_index do |long_name, index|
              merged_col[long_name] = val[index]
            end
          else
            separate_col[merged_columns[0]] = val
          end
        end
        separate_col.merge(merged_col)
      end

      def get_short_key_name(condition)
        table_info[:merged_columns].
            select {|_, v| v[:keys].sort == condition.sort}.keys.first
      end


    end

    class_methods do
      def table (table_info)
        self.table_info = table_info
      end

      def raw_table_name
        self.table_info[:raw_name]
      end

    end

  end
end

