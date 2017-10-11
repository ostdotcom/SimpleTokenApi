module Util

  module SignalHandler

    # Register Handlers which would have this Cron Instance interuppt, kill etc ..
    #
    # * Author: Puneet
    # * Date: 10/10/2017
    # * Reviewed By:
    #
    def register_signal_handlers
      puts "\n\n\n\nAdding handler\n\n\n"
      @continue_running = true
      ['INT', 'QUIT', 'TERM'].each do |sig|
        Signal.trap(sig) { puts "\n\n\nTrapped - #{sig} "; @continue_running = false }
      end
    end

  end

end
