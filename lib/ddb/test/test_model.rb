module Ddb
  module Test
    class TestModel < Ddb::Base

      include Ddb::Table

      table :raw_name => 'test_model',
            :partition_key => TestConstants.partition_key,
            :sort_key => TestConstants.sort_key,
            :indexes => TestConstants.indexes,
            :merged_columns => TestConstants.merged_columns,
            :delimiter => "#"

      def initialize(params, options = {})
        super
      end

    end
  end
end


