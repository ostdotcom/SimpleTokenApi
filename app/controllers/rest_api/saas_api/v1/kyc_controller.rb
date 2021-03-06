class RestApi::SaasApi::V1::KycController < RestApi::SaasApi::V1::BaseController
  # Add KYC
  #
  # * Author: Aman
  # * Date: 27/12/2017
  # * Reviewed By:
  #
  def add_kyc
    service_response = SaasManagement::AddUser.new(client: params[:client],
                                                   email: params[:email],
                                                   user_ip_address: params[:user_ip_address]).perform

    if service_response.success?
      service_response = UserManagement::Kyc::Submit.new(params.merge(user_id: service_response.data[:user_id])).perform
      if service_response.success?
        service_response.data = {user_id: service_response.data[:user_kyc_detail][:user_id]}
      end
    end

    render_api_response(service_response)
  end


  # Get upload file params
  #
  # * Author: Aman
  # * Date: 04/01/2018
  # * Reviewed By:
  #
  def get_upload_params
    service_response = UserManagement::DocumentsUploader::SignedPostParams.new(params).perform
    render_api_response(service_response)
  end

  # Check if ethereum address is valid
  #
  # * Author: Aman
  # * Date: 22/01/2018
  # * Reviewed By:
  #
  def check_ethereum_address
    service_response = UserManagement::CheckEthereumAddress.new(params).perform
    render_api_response(service_response)
  end

  # Get User detail
  #
  # * Author: Aman
  # * Date: 09/04/2018
  # * Reviewed By:
  #
  def get_detail
    service_response = SaasManagement::GetUserDetail.new(params).perform
    render_api_response(service_response)
  end

end
