class Callback::OpsController < Callback::BaseController

  protect_from_forgery except: ['whitelist_event']

  before_action :decrypt_jwt

  # Whitelist event callback
  #
  # * Author: Aman
  # * Date: 25/10/2017
  # * Reviewed By: Sunil
  #
  def whitelist_event
    service_response = WhitelistManagement::RecordEvent.new(params).perform
    render_api_response(service_response)

  end

  private

  # Decrypt jwt
  #
  # * Author: Kedar
  # * Date: 28/10/2017
  # * Reviewed By: Sunil
  #
  def decrypt_jwt
    begin
      params[:decoded_token_data] = JWT.decode(
        params[:token],
        GlobalConstant::PublicOpsApi.secret_key,
        true,
        {:algorithm => 'HS256'}
      )[0]["data"]
    rescue => e
      # decoding failed
      ApplicationMailer.notify(
          body: {exception: {message: e.message, backtrace: e.backtrace}},
          data: {
              'decoded_token_data' => params[:decoded_token_data],
              'token' => params[:token]
          },
          subject: 'Exception in decrypt_jwt'
      ).deliver

      render_api_response(
        Result::Base.error({
                             error: 'c_oc_1',
                             error_message: 'Token Invalid or Expired.',
                             http_code: GlobalConstant::ErrorCode.not_found
                           })
      )
    end
  end

end