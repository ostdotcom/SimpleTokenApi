module Util

  module SignalHandler

    # Register Handlers which would have this Cron Instance interuppt, kill etc ..
    #
    # * Author: Puneet
    # * Date: 10/10/2017
    # * Reviewed By: Sunil
    #
    def register_signal_handlers
      puts "*** Adding handler register_signal_handlers ***"

      ['INT', 'QUIT', 'TERM'].each do |sig|
        Signal.trap(sig) {
          puts "\n\n\nTrapped - #{sig} ";
          GlobalConstant::SignalHandling.sigint_received!
        }
      end
    end

  end

end
