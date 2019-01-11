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
        def format_person_search_query_data(query_params)
          query_params.merge!(GlobalConstant::Aml.default_query_data)
          map_query_params(query_params)
        end

        # Formats query params as per aml partner's convention
        #
        # * Author: Mayur Patil
        # * Date: 9/1/2019
        # * Reviewed By:
        #
        # @return [Hash]
        #
        def map_query_params(query_params)
          mapped_params = GlobalConstant::Aml.query_data_mapping
          temp_params = {}

          query_params.each do |key, val|
            val = formatted_dob(val) if key == 'birthdate'

            if mapped_params[key].present?
              temp_params[mapped_params[key]] = val
            else
              temp_params[key] = val
            end
          end
          temp_params
        end

        # Formats The DOB as per the acuris api format
        #
        # * Author: Mayur Patil
        # * Date: 9/1/2019
        # * Reviewed By:
        #
        # @return [String]
        #
        def formatted_dob(dob_string)
          dob_string
        end

      end
    end
  end
end