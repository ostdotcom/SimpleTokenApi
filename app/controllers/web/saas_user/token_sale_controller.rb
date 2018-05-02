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
    service_response = UserManagement::KycSubmit.new(params).perform
    render_api_response(service_response)
  end

  # branded token name submit
  #
  # * Author: Kedar
  # * Date: 11/10/2017
  # * Reviewed By: Sunil
  #
  def bt_submit
    service_response = UserManagement::BtSubmit.new(params).perform
    render_api_response(service_response)
  end

  # Get upload file params
  #
  # * Author: Kedar
  # * Date: 13/10/2017
  # * Reviewed By: Sunil
  #
  def get_upload_params
    service_response = UserManagement::GetUploadParams.new(params).perform
    render_api_response(service_response)
  end

  # Get ethereum address and balance if sale is live
  #
  # * Author: Aman
  # * Date: 28/10/2017
  # * Reviewed By: Sunil
  #
  def check_ethereum_balance
    service_response = UserManagement::CheckEthereumBalance.new(params).perform
    render_api_response(service_response)
  end

  # Send Double Opt In again
  #
  # * Author: Aman
  # * Date: 13/10/2017
  # * Reviewed By: Sunil
  #
  #  todo: "KYCaas-Changes"
  # def resend_double_opt_in
  #   BgJob.enqueue(
  #       SendDoubleOptIn,
  #       {
  #           user_id: params[:user_id]
  #       }
  #   )
  #
  #   r = Result::Base.success({})
  #   render_api_response(r)
  # end

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
