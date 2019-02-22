class Web::Iframe::KycController < Web::Iframe::BaseController

  # Get user details with tokens
  #
  # * Author: Aman
  # * Date: 13/10/2017
  # * Reviewed By: Sunil
  #
  def basic_detail
    # use a diff service
    service_response = UserManagement::GetBasicDetail.new(params).perform
    render_api_response(service_response)
  end

  # Submit KYC
  #
  # * Author: Kedar
  # * Date: 11/10/2017
  # * Reviewed By: Sunil
  #
  def kyc_submit
    service_response = UserManagement::Kyc::Submit.new(params).perform

    if service_response.success?
      service_response.data = {user_id: service_response.data[:user_kyc_detail][:user_id]}
    end
    render_api_response(service_response)
  end


  # Get upload file params
  #
  # * Author: Kedar
  # * Date: 13/10/2017
  # * Reviewed By: Sunil
  #
  def get_upload_params
    service_response = UserManagement::DocumentsUploader::SignedPostParams.new(params).perform
    render_api_response(service_response)
  end

end
