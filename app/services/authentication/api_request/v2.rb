module Authentication::ApiRequest

  EXPIRATION_WINDOW_V2 = 10.seconds

  class V2 < Base

    def initialize(params)
      super
    end

    # Get request time
    #
    # * Author: Aniket
    # * Date: 18/09/2018
    # * Reviewed By:
    #
    def request_time
      @params[:request_timestamp]
    end


    # Get expiry window
    #
    # * Author: Aniket
    # * Date: 18/09/2018
    # * Reviewed By:
    #
    def expiry_window
      EXPIRATION_WINDOW_V2
    end

    # Get url path
    #
    # * Author: Aniket
    # * Date: 21/09/2018
    # * Reviewed By:
    #
    def get_url_path
      @url_path
    end
  end
end