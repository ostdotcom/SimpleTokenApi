module EstimatedGasPrice
  class GasStationPrediction

    require 'net/http'

    REQUEST_TIMEOUT = 5

    # Initialize
    #
    # * Author: Pankaj
    # * Date: 18/09/2018
    # * Reviewed By:
    #
    # @return [EstimatedGasPrice::GasStationPrediction]
    #
    def initialize()
      @gas_json = {}
    end

    # Perform
    #
    # * Author: Pankaj
    # * Date: 18/09/2018
    # * Reviewed By:
    #
    # @return [Integer]
    #
    def perform
      @gas_json = fetch_gasstation_json

      return 0 if @gas_json.blank?

      parse_json_response
    end

    private

    # Make Call to Eth gas station and fetch prediction list
    #
    # * Author: Pankaj
    # * Date: 18/09/2018
    # * Reviewed By:
    #
    def fetch_gasstation_json
      begin
        url = "https://ethgasstation.info/json/predictTable.json"
        uri = URI.parse(url)

        Timeout.timeout(REQUEST_TIMEOUT) do
          response = Net::HTTP.get(uri)

          Oj.load(response)
        end
      rescue Timeout::Error => e
        send_email(e)
        {}

      rescue Exception => e
        send_email(e)
        {}
      end
    end

    # Iterate over json response and find estimate gas predicted
    #
    # * Author: Pankaj
    # * Date: 18/09/2018
    # * Reviewed By:
    #
    def parse_json_response
      last_non_zero_remaining_5m = 0

      @gas_json.is_a?(Array) && @gas_json.present? && @gas_json.each do |x|
        if x["pct_remaining5m"].to_f > 0
          last_non_zero_remaining_5m = x["gasprice"].to_f
        end
      end

      last_non_zero_remaining_5m > 0 ? last_non_zero_remaining_5m : 0
    end

    # Send Exception email
    #
    # * Author: Pankaj
    # * Date: 18/09/2018
    # * Reviewed By:
    #
    def send_email(exception)
      ApplicationMailer.notify(
          body: {message: exception.message, backtrace: exception.backtrace},
          subject: "Exception in fetching Prediction Gas from Gas Station"
      ).deliver
    end

  end
end