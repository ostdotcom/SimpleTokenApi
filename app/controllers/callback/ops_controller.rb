class Callback::OpsController < Callback::BaseController

  before_action :decrypt_jwt

  # Whitelist event callback
  #
  # * Author: Aman
  # * Date: 11/11/2017
  # * Reviewed By:
  #
  def whitelist_event
    BgJob.enqueue(WhitelistCallbackJob, {decoded_token_data: params[:decoded_token_data]})

    r = Result::Base.success({})
    render_api_response(r)
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
      decoded_token_data = JWT.decode(
        params[:token],
        GlobalConstant::PublicOpsApi.secret_key,
        true,
        {:algorithm => 'HS256'}
      )[0]["data"]

      params[:decoded_token_data] = HashWithIndifferentAccess.new(decoded_token_data)
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