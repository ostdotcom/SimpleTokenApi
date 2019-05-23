class RestApi::OstPaymentClientController < RestApi::RestApiController

  include Util::ResultHelper

  def save_payment_detail
    service_response = success_with_data({})
    render_api_response(service_response)
  end


end
