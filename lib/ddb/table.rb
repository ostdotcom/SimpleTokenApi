module Ddb
  module Table
    extend ActiveSupport::Concern
    included do
      cattr_accessor :table_options
      attr_accessor :attributes

      def query
        table_options[:name] = table_name
        query = Ddb::QueryBuilder::Query.new(@raw_conditions, table_options).perform
      end

      def get_item

      end

      def scan

      end
    end

    class_methods do
      def table (table_options)
        self.table_options = table_options
      end

      def raw_table_name
        self.table_options[:name]
      end

      def partition_key
        self.table_options[:partition_key]
      end

      def sort_key
        self.table_options[:sort_key]
      end

    end

  end
end
