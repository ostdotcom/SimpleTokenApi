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

      def self.enum
        {
            image_processing_status: {
                GlobalConstant::ImageProcessing.unprocessed_image_process_status => 0 ,
                GlobalConstant::ImageProcessing.processed_image_process_status => 1,
                GlobalConstant::ImageProcessing.failed_image_process_status => 2

            }
        }.with_indifferent_access
      end

      def initialize(params, options = {})
        super
      end

    end
  end
end


