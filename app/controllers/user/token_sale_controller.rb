class User::TokenSaleController < User::BaseController

  # Submit KYC
  #
  # * Author: Kedar
  # * Date: 11/10/2017
  # * Reviewed By: Sunil
  #
  def kyc_submit
    # res = verify_recaptcha
    # render_api_response(res) and return unless res.success?
    service_response = UserManagement::KycSubmit.new(
        params.merge(
            g_recaptcha_response: params['g-recaptcha-response'],
            remoteip: request.remote_ip
        )
    ).perform
    render_api_response(service_response)
  end

  # Submit KYC
  #
  # * Author: Kedar
  # * Date: 11/10/2017
  # * Reviewed By: Sunil
  #
  def bt_submit
    service_response = UserManagement::BtSubmit.new(params).perform
    render_api_response(service_response)
  end

  # Get logged in user details
  #
  # * Author: Kedar
  # * Date: 13/10/2017
  # * Reviewed By: Sunil
  #
  def get_upload_params
    service_response = UserManagement::GetUploadParams.new(params).perform
    render_api_response(service_response)
  end

  # Send Double Opt In again
  #
  # * Author: Aman
  # * Date: 13/10/2017
  # * Reviewed By: Sunil
  #
  def resend_double_opt_in
    BgJob.enqueue(
        OnBTSubmitJob,
        {
            user_id: params[:user_id]
        }
    )

    r = Result::Base.success({})
    render_api_response(r)
  end

  # private
  #
  # # verify captcha
  # #
  # # * Author: Aman
  # # * Date: 13/10/2017
  # # * Reviewed By: Sunil
  # #
  # def verify_recaptcha
  #   r = Recaptcha::Verify.new({
  #                                 'response' => params['g-recaptcha-response'],
  #                                 'remoteip' => request.remote_ip
  #                             }).perform
  # end

end
