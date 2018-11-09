class RestApi::Sandbox::ClientController < RestApi::Sandbox::BaseController

  before_action :decrypt_jwt

  include Util::ResultHelper

  # # Get all account settings details of client.
  # #
  # # * Author: Aman
  # # * Date: 05/11/2018
  # # * Reviewed By:
  # #
  # # This api call is used by prod env to get clients info
  # #
  # def get_sandbox_account_setup_details
  # # service to send data
  # # data should be encrypted using encrypt token
  # #   #   kms_client = Aws::Kms.new('saas', 'saas')
  # #   r = kms_client.decrypt(GeneralSalt.client_setting_data_salt_type)
  # #   r.data[:plaintext]
  # end

  # Get Published Draft
  #
  # * Author: Tejas
  # * Date: 14/08/2018
  # * Reviewed By:
  #
  def get_published_drafts
    service_response = AdminManagement::CmsConfigurator::GetPublishedDraft.new(params).perform
    render_api_response(service_response)
  end

  private

  # Decrypt jwt
  #
  # * Author: Aman
  # * Date: 09/11/2018
  # * Reviewed By:
  #
  def decrypt_jwt
    begin
      public_key = OpenSSL::PKey::RSA.new(GlobalConstant::PublicOpsApi.sandbox_env_rsa_public_key)

      decoded_token_data = JWT.decode(
        params[:token],
        public_key,
        true,
        {:algorithm => 'RS256'}
      )[0]["data"]

      params[:decoded_token_data] = decoded_token_data
    rescue => e
      # decoding failed
      ApplicationMailer.notify(
          body: {exception: {message: e.message, backtrace: e.backtrace}},
          data: {
              'decoded_token_data' => params[:decoded_token_data],
              'token' => params[:token]
          },
          subject: 'Exception in decrypt jwt in client controller'
      ).deliver

      render_api_response(
        Result::Base.error({
                             error: 's_cc_1',
                             error_message: 'Token Invalid or Expired.',
                             http_code: GlobalConstant::ErrorCode.not_found
                           })
      )
    end
  end

end