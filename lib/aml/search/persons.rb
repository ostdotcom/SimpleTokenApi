module Aml
  module Search
    class Persons < ::Aml::Base

      def initialize(params={})
        super
      end

      def data_by_query(query_params)
        post_request( get_search_base_url + data_by_query_endpoint,
                      Formatter::RequestFormatter.new.format_query_data(query_params))
      end

      def record_by_qr_code(query_params)

        qr_code = query_params.delete('qr_code')

        get_request( get_search_base_url + record_by_qr_code_endpoint(qr_code), query_params)
      end

      def pdf_by_qr_code(query_params)

        qr_code = query_params.delete('qr_code')

        get_request( get_search_base_url + pdf_by_qr_code_endpoint(qr_code), query_params)
      end


      def data_by_query_endpoint
        "/api/v2_1/api/persons/search"
      end

      def record_by_qr_code_endpoint(qr_code)

        raise "qr_code is not present in query_params" unless qr_code.present?

        "/api/v2_1/api/persons/#{qr_code}"

      end

      def pdf_by_qr_code_endpoint(qr_code)

        raise "qr_code is not present in query_params" unless qr_code.present?

        "/api/v2_1/api/persons/profilePDF/#{qr_code}"
      end


      private

      def get_search_base_url
        GlobalConstant::Base.aml_config[:search][:base_url]
      end


    end
  end
end