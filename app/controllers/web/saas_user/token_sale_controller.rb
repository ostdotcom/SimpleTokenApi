class Web::SaasUser::TokenSaleController < Web::SaasUser::BaseController

  before_action :verify_recaptcha, only: [:kyc_submit]

  # Send Double Opt In again
  #
  # * Author: Aman
  # * Date: 02/05/2018
  # * Reviewed By:
  #
  def resend_double_opt_in
    BgJob.enqueue(
        SendDoubleOptIn,
        {
            client_id: params[:client_id],
            user_id: params[:user_id]
        }
    )

    r = Result::Base.success({})
    render_api_response(r)
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


  # Check if ethereum address is valid
  #
  # * Author: Abhay
  # * Date: 31/10/2017
  # * Reviewed By: Sunil
  #
  def check_ethereum_address
    service_response = UserManagement::CheckEthereumAddress.new(params).perform
    render_api_response(service_response)
  end

end
