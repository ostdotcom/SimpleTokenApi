module Authentication::ApiRequest

  EXPIRATION_WINDOW_V1 = 5.minutes

  class V1 < Base

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
      @params[:request_time]
    end

    # Get expiry window
    #
    # * Author: Aniket
    # * Date: 18/09/2018
    # * Reviewed By:
    #
    def expiry_window
      EXPIRATION_WINDOW_V1
    end

    # Get url path
    #
    # * Author: Aniket
    # * Date: 21/09/2018
    # * Reviewed By:
    #
    def get_url_path
      "#{@url_path}/"
    end

  end
end