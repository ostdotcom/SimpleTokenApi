module Ddb
  module Table
    extend ActiveSupport::Concern

    include Util::ResultHelper

    included do
      cattr_accessor :table_info

      def self.allowed_params
        GlobalConstant::Aws::Ddb::Config.allowed_params
      end


      def query(query)
        instance_array = []
        r = validate_for_ddb_options(query, self.class.allowed_params[:query])
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
        ddb_r = Ddb::Api::Query.new(params: r.data).perform
        return ddb_r unless ddb_r.success?

        parsed_resp = use_column_mapping? ? parse_response_array(ddb_r.data[:data][:items]) : ddb_r.data[:data][:items]

        parsed_resp.each do |resp|
          instance_array << self.class.new(@params, @options).initialize_instance_variables(resp)
        end

        success_with_data(data: instance_array)
      end


      def delete_item(item)
        r = validate_for_ddb_options(item, self.class.allowed_params[:delete_item])
        return r unless r.success?

        r = validate_item item[:key]
        return r unless r.success?

        item[:key] = use_column_mapping? ? params_mapping(item[:key]) : item[:key]

        r = Ddb::QueryBuilder::DeleteItem.new({params: item, table_info: table_info}).perform

        return r unless r.success?
        ddb_r = Ddb::Api::DeleteItem.new(params: r.data).perform
        return ddb_r unless ddb_r.success?


        attributes = use_column_mapping? && ddb_r.data[:data][:attributes].present? ?
                         parse_response(ddb_r.data[:data][:attributes]) : ddb_r.data[:data][:attributes]

        success_with_data(data: initialize_instance_variables(attributes))
      end


      def get_item(item)

        r = validate_for_ddb_options(item, self.class.allowed_params[:get_item])
        return r unless r.success?

        r = validate_item item[:key]
        return r unless r.success?

        item[:key] = use_column_mapping? ? params_mapping(item[:key]) : item[:key]

        r = Ddb::QueryBuilder::GetItem.new({params: item, table_info: table_info}).perform

        return r unless r.success?
        ddb_r = Ddb::Api::GetItem.new(params: r.data).perform
        return ddb_r unless (ddb_r.success? && ddb_r[:item].present?)

        ddb_r = ddb_r.data[:data]
        ddb_r[:item] = use_column_mapping? && ddb_r[:item].present? ? parse_response(ddb_r[:item]) : ddb_r[:item]
        processed_data = process_dynamo_data(ddb_r[:item])
        success_with_data(data: initialize_instance_variables(processed_data))

      end


      def put_item(item)

        r = validate_for_ddb_options(item, self.class.allowed_params[:put_item])
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
        success_with_data(data: initialize_instance_variables(attributes))
      end


      def scan(query = {})

        instance_array = []

        r = validate_for_ddb_options(query, self.class.allowed_params[:scan])
        return r unless r.success?

        query = use_column_mapping? ? query_params_mapping(query) : query

        r = Ddb::QueryBuilder::Scan.new({params: query, table_info: table_info}).perform
        return r unless r.success?
        ddb_r = Ddb::Api::Scan.new(params: r.data).perform
        return ddb_r unless ddb_r.success?
        parsed_resp = parse_response_array(ddb_r.data[:data][:items])

        parsed_resp.each do |resp|
          instance_array << self.class.new(@params, @options).initialize_instance_variables(resp)
        end

        success_with_data(data: instance_array)

      end

      def update_item(item)

        r = validate_for_ddb_options(item, self.class.allowed_params[:update_item])
        return r unless r.success?


        r = validate_item item[:key]
        return r unless r.success?


        item = update_params_mapping(item)

        r = Ddb::QueryBuilder::UpdateItem.new({params: item, table_info: table_info}).perform

        return r unless r.success?


        ddb_r = Ddb::Api::UpdateItem.new(params: r.data).perform
        ddb_r unless ddb_r.success?
        success_with_data(data: initialize_instance_variables(ddb_r.data[:data].attributes))
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


      def batch_write(items)
        items_list, resp_list, instance_array = [], [], []
        r = validate_for_ddb_options(items, self.class.allowed_params[:batch_write])
        cnt = 0
        return r unless r.success?
        items[:items].each do |item|
          r = validate_item item
          return r unless r.success?
          items_list << params_mapping(item)
        end

        r = Ddb::QueryBuilder::BatchWrite.new({params: {items: items_list}, table_info: table_info}).perform

        ddb_r = Ddb::Api::BatchWrite.new(params: r.data).perform

        list = ddb_r.data[:data][:unprocessed_items][table_info[:name].to_s]
        list.each do |l|
          resp_list << use_column_mapping? ? parse_response(l["put_request"]["item"]) : l["put_request"]["item"]
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


      def update_params_mapping(item)
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

      def process_dynamo_data(data)
        list_of_integer_keys = self.class.list_of_integer_keys
        list_of_integer_keys.each do |key|
          data[key] = data[key].to_i
        end if data.present?
        data
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
