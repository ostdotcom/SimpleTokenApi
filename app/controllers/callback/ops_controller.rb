class Callback::OpsController < Callback::BaseController

  protect_from_forgery except: ['whitelist_event']

  # Whitelist event callback
  #
  # * Author: Aman
  # * Date: 25/10/2017
  # * Reviewed By:
  #
  def whitelist_event
    Rails.logger.debug("\n\n--------#{params}\n\n")

    service_response = WhitelistManagement::RecordEvent.new(params).perform
    render_api_response(service_response)

  end

end