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
        post_request( get_search_base_url + data_by_query_endpoint,
                      Formatter::RequestFormatter.new.format_query_data(query_params))
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

        get_request( get_search_base_url + record_by_qr_code_endpoint(qr_code), query_params)
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

        get_request( get_search_base_url + pdf_by_qr_code_endpoint(qr_code), query_params)
      end

      # data by query endpoint
      #
      # * Author: mayur
      # * Date: 8/1/2019
      # * Reviewed By:
      #
      #
      #
      # @return [String]
      #
      def data_by_query_endpoint
        "/api/v2_1/api/persons/search"
      end


      # record by qr code endpoint
      #
      # * Author: mayur
      # * Date: 8/1/2019
      # * Reviewed By:
      #
      #
      #
      # @return [String]
      #
      def record_by_qr_code_endpoint(qr_code)

        raise "qr_code is not present in query_params" unless qr_code.present?

        "/api/v2_1/api/persons/#{qr_code}"

      end

      # pdf by qr code endpoint
      #
      # * Author: mayur
      # * Date: 8/1/2019
      # * Reviewed By:
      #
      #
      #
      # @return [String]
      #
      def pdf_by_qr_code_endpoint(qr_code)

        raise "qr_code is not present in query_params" unless qr_code.present?

        "/api/v2_1/api/persons/profilePDF/#{qr_code}"
      end


      private

      # get search base url
      #
      # * Author: mayur
      # * Date: 8/1/2019
      # * Reviewed By:
      #
      #
      #
      # @return [String]
      #
      def get_search_base_url
        GlobalConstant::Base.aml_config[:search][:base_url]
      end

    end
  end
end