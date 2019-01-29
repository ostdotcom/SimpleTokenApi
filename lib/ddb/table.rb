module Ddb
  module Table
    extend ActiveSupport::Concern

    include Util::ResultHelper

    included do
      cattr_accessor :table_info

      def query(query)
        query = use_column_mapping? ? query_params_mapping(query) : query
        r = Ddb::QueryBuilder::Query.new({params: query, table_info: table_info}).perform
        return r unless r.success?
        ddb_r = Ddb::Api::Query.new(r.data).perform
        return ddb_r unless ddb_r.success?
        ddb_r[:items] = parse_response_array(ddb_r.data[:items])
        success_with_data(data: ddb_r)
      end

      def query_params_mapping(query)
        query[:key_conditions].each_with_index do |attr, index|
          query[:key_conditions][index][:attribute] = params_mapping(attr[:attribute])
        end if query[:key_conditions].present?

        query[:filter_conditions][:conditions].each_with_index do |attr, index|
          query[:filter_conditions][:conditions][index][:attribute] = params_mapping(attr[:attribute])
        end if query[:filter_conditions].present?

        query
      end


      def update_item(item)
        item = update_params_mapping(item)
        r = Ddb::QueryBuilder::UpdateItem.new({params: item, table_info: table_info}).perform
        return r unless r.success?
        ddb_r = Ddb::Api::UpdateItem.new(r.data).perform
        ddb_r unless ddb_r.success?
        success_with_data(data: ddb_r)
      end


      def update_params_mapping(item)
        return item unless use_column_mapping?
        remove_list = []
        item[:key] = params_mapping(item[:key])
        [:set, :add].each do |operation|
          item[operation].each_with_index do |set_item, index|
            item[operation][index][:attribute] = params_mapping(set_item[:attribute])
          end if item[operation].present?
        end
        item[:remove].each do |remove_item|
          remove_list << get_short_key_name([remove_item])
        end if item[:remove].present?
        item[:remove] = remove_list
        item
      end

      def put_item(item)
        item[:item] = use_column_mapping? ? params_mapping(item[:item]) : item[:item]
        r = Ddb::QueryBuilder::PutItem.new({params: item, table_info: table_info}).perform
        return r unless r.success?
        ddb_r = Ddb::Api::PutItem.new(params: r.data, retry_count: 3).perform
        ddb_r unless ddb_r.success?
        success_with_data(data: ddb_r)
      end


      def get_item(item)
        item[:key] = use_column_mapping? ? params_mapping(item[:key]) : item[:key]
        r = Ddb::QueryBuilder::GetItem.new({params: item, table_info: table_info}).perform
        return r unless r.success?
        ddb_r = Ddb::Api::GetItem.new(r.data).perform
        return ddb_r unless ddb_r.success?
        ddb_r = ddb_r.data[:data]
        ddb_r[:item] = use_column_mapping? && ddb_r[:item].present? ? parse_response(ddb_r[:item]) : ddb_r[:item]
        success_with_data(data: ddb_r)
      end


      def delete_item(item)
        item[:key] = use_column_mapping? ? params_mapping(item[:key]) : item[:key]
        r = Ddb::QueryBuilder::DeleteItem.new({params: item, table_info: table_info}).perform
        return r unless r.success?
        ddb_r = Ddb::Api::DeleteItem.new(r.data).perform
        return ddb_r unless ddb_r.success?
        success_with_data(data: ddb_r.data)
      end

      def batch_write(items)
        items.each_with_index do |item, index|
          items[index][:put_request][:item] = params_mapping(item[:put_request][:item])
        end
        r = Ddb::QueryBuilder::BatchWrite.new({params: items, table_info: table_info}).perform
        ddb_r = Ddb::Api::BatchWrite.new(r.data).perform
        return ddb_r unless ddb_r.success?
        success
      end


      def params_mapping(item)
        s_n_h = {}
        item.deep_symbolize_keys!
        table_info[:merged_columns].each do |short_name, columns_info|
          if item.values_at(*columns_info[:keys]).all? {|e| e.present?} # => true
            s_n_h[short_name] = columns_info[:keys].length == 1 ? item[columns_info[:keys][0]] :
                                    item.values_at(*columns_info[:keys]).compact.join(table_info[:delimiter])
          end
        end
        s_n_h.delete_if {|_, v| v.blank?}
      end


      def scan(query = {})
        query = use_column_mapping? ? query_params_mapping(query) : query
        r = Ddb::QueryBuilder::Scan.new({params: query, table_info: table_info}).perform
        return r unless r.success?
        ddb_r = Ddb::Api::Scan.new(r.data).perform
        return ddb_r unless ddb_r.success?
        ddb_r[:items] = parse_response_array(ddb_r.data[:items])
        success_with_data(data: ddb_r)
      end

      def parse_response_array(item_list)
        items = []
        item_list.each do |item|
          items << parse_response(item)
        end
        items
      end

      def parse_response(r)
        res = {}
        r.each do |k, v|
          v = v.class == String ? v.split(table_info[:delimiter]) : v
          table_info[:merged_columns][k][:keys].each_with_index do |long_name, index|
            res[long_name] = v.class == Array ? v[index] : v
          end
        end
        res
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



