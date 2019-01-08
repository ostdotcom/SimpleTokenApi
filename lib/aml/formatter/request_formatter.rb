module Aml
  module Formatter
    class RequestFormatter

      def initialize
        @params = nil
      end

      def format_query_data(query_params)

        @params = query_params

        merge_search_params

        map_query_params

      end

      def merge_search_params

        @params.merge! (GlobalConstant::Aml.default_query_data)

      end

      def map_query_params

        mapped_params = GlobalConstant::Aml.query_data_mapping
        temp_params = {}

        @params.each do |key, val|
          if mapped_params[key].present?
            temp_params[mapped_params[key]] = val
          else
            temp_params[key] = val
          end
        end
        temp_params
      end

    end
  end
end