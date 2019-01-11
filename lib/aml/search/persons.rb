module Aml
  module Search
    class Persons < ::Aml::Base

      def initialize
        super
      end

      # Records by query
      #
      # * Author: mayur
      # * Date: 8/1/2019
      # * Reviewed By:
      #
      # @param [Hash] query_params
      #
      # @return [Result::Base]
      #
      def data_by_query(query_params)
        post_request( "/api/v2_1/api/persons/search",
                      Formatter::RequestFormatter.format_person_search_query_data(query_params))
      end


      # Single Record by qr_code
      #
      # * Author: mayur
      # * Date: 8/1/2019
      # * Reviewed By:
      #
      # @param [Hash] query_params
      #
      # @return [Result::Base]
      #
      def record_by_qr_code(query_params)
        qr_code = query_params.delete('qr_code')
        get_request( "/api/v2_1/api/persons/#{qr_code}", {}, {has_string_response: true})
      end

      # PDF by qr_code
      #
      # * Author: mayur
      # * Date: 8/1/2019
      # * Reviewed By:
      #
      # @param [Hash] query_params
      #
      # @return [Result::Base]
      #
      def pdf_by_qr_code(query_params)
        qr_code = query_params.delete('qr_code')
        get_request( "/api/v2_1/api/persons/profilePDF/#{qr_code}")
      end

      # Country list
      #
      # * Author: mayur
      # * Date: 11/1/2019
      # * Reviewed By:
      #
      # @param [Hash] query_params
      #
      # @return [Result::Base]
      #
      def country_list
        get_request( "/api/v2_1/api/countries")
      end

      private

      # get search base url for person
      #
      # * Author: mayur
      # * Date: 8/1/2019
      # * Reviewed By:
      #
      #
      #
      # @return [String]
      #
      def base_url
        GlobalConstant::Base.aml_config[:search][:base_url]
      end

    end
  end
end