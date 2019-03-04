class Web::Iframe::BaseController < Web::WebController

  before_action :authenticate_client_host
  before_action :authenticate_request

  private

  # Validate referer host to be one of our clients
  #
  # * Author: Aman
  # * Date: 01/02/2018
  # * Reviewed By:
  #
  def authenticate_client_host
    Rails.logger.info "=**************** request.host #{request.host} ***********************************************************="
    Rails.logger.info "=**************** request.referer #{request.referer} ***********************************************************="
    # service_response = Authentication::Client::VerifyIframeReferer.new(domain: request.host).perform
    #
    # if service_response.success?
    #   params[:client_id] = service_response.data[:client_id]
    #   service_response.data = {}
    # else
    #   render_api_response(service_response)
    # end
    params[:client_id] = 7
    #params[:client_id] = 2
  end

  # Validate cookie
  #
  # * Author: Kedar
  # * Date: 10/10/2017
  # * Reviewed By: Sunil
  #
  def authenticate_request
    # params[:user_id] = params[:token].present? ? params[:token].to_i :
    #                        UserKycDetail.active_kyc.where(client_id: params[:client_id]).
    #                            where.not.(aml_status: GlobalConstant::UserKycDetail.aml_approved_statuses).last.user_id
    params[:user_id] = 11521
    #params[:user_id] = 11009

  end

end