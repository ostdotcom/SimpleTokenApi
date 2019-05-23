class RestApi::OstPaymentController < RestApi::RestApiController

  include Util::ResultHelper

  NOUNCE = '12345'

  def get_token
    #   send ost platform token
    service_response = success_with_data({token: "ABCDEFG"})
    render_api_response(service_response)
  end

  def get_braintree_token
    #   make api call to braintree to get token
    service_response = success_with_data({braintree_token: ""})
    render_api_response(service_response)
  end

  def save_nounce
    #   save nounce in db
    service_response = success_with_data({payment_option_id: ''})
    render_api_response(service_response)
  end

  def add_card
    #   make api call to braintree to add card using nounce
    service_response = success_with_data({payment_type_id: "123456"})
    render_api_response(service_response)
  end

  def charge_card
    #   make api call to braintree to charge card using nounce
    service_response = success_with_data({payment_id: "123456"})
    render_api_response(service_response)
  end

end
