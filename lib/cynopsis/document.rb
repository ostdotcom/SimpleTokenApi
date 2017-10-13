module Cynopsis

  class Document < Cynopsis::Base

    # Initialize
    #
    # * Author: Sunil Khedar
    # * Date: 10/10/2017
    # * Reviewed By:
    #
    # @return [Cynopsis::Document]
    #
    def initialize
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
    #
    # @return [Result::Base]
    #
    def upload(params)
      params[:domain_name] = GlobalConstant::Cynopsis.domain_name
      params[:file] = HTTP::FormData::File.new(params[:local_file_path])
      params[:filename] = params[:local_file_path].split('/').last
      params.delete(:local_file_path)

      upload_request('/default/individual_file_upload', params)
    end

  end

end