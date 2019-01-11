module Aml
  module Formatter
    class RequestFormatter

      class << self

      # Format search query data
      #
      # * Author: Mayur Patil
      # * Date: 9/1/2019
      # * Reviewed By:
      #
      # @params [Hash] query_params
      # @return [Hash]
      #
      def format_query_data(query_params)

        @params = query_params

        merge_search_params

        map_query_params

      end

      # Merges search params with default search params
      #
      # * Author: Mayur Patil
      # * Date: 9/1/2019
      # * Reviewed By:
      #
      # @return [Hash]
      #
      def merge_search_params

        @params.merge! (GlobalConstant::Aml.default_query_data)

      end

      # Formats query params as per aml partner's convention
      #
      # * Author: Mayur Patil
      # * Date: 9/1/2019
      # * Reviewed By:
      #
      # @return [Hash]
      #
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
  end