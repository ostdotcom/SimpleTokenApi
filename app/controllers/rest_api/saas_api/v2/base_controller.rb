class RestApi::SaasApi::V2::BaseController < RestApi::SaasApi::BaseController

  private

  # Get authenticator route
  #
  # * Author: Pankaj
  # * Date: 18/09/2018
  # * Reviewed By:
  #
  def authenticator
    Authentication::ApiRequest::V2
  end

  # No formatting required
  #
  # * Author: Pankaj
  # * Date: 18/09/2018
  # * Reviewed By:
  #
  def format_api_response(response_hash)
    super
    # TODO: Remove this code after sometime as this is a temp solution to detect error data
    if response_hash[:http_code] == GlobalConstant::ErrorCode.ok && !response_hash[:success]
      ApplicationMailer.notify(
          to: GlobalConstant::Email.default_to,
          body: "Error received with 200 Http Code for an Api",
          data: response_hash,
          subject: "Error received with 200 Http Code for an Api"
      ).deliver
      response_hash[:http_code] = response_hash[:err][:error_data].present? ?
                                      GlobalConstant::ErrorCode.invalid_request_parameters : GlobalConstant::ErrorCode.unprocessable_entity
    end
    response_hash
  end

end