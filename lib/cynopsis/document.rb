module Cynopsis

  class Document < Cynopsis::Base

    # Initialize
    #
    # * Author: Sunil Khedar
    # * Date: 10/10/2017
    # * Reviewed By:
    #
    # @params [Integer] client id (mandatory) - Client id

    # @return [Cynopsis::Document]
    #
    def initialize(params)
      super
    end

    # Upload individual customer documents
    #
    # * Author: Sunil Khedar
    # * Date: 10/10/2017
    # * Reviewed By:
    #
    # @params [String] rfrID (mandatory) - Customer reference id
    # @params [String] local_file_path (mandatory) - document local path
    # @params [String] document_type (mandatory) - document type
    # @params [String] please_mention (mandatory) - when document type id "OTHERS", give unique name to it
    #
    # @return [Result::Base]
    #
    def upload(params)
      params[:domain_name] = client_cynopsis_detail.domain_name
      params[:file] = HTTP::FormData::File.new(params[:local_file_path])
      params[:filename] = params[:local_file_path].split('/').last
      params.delete(:local_file_path)

      upload_request('/default/individual_file_upload', params)
    end

  end

end