# frozen_string_literal: true
module GlobalConstant

  class LocalPath

    class << self

      def geo_ip_file
        GlobalConstant::Base.local_path['geo_ip_file']
      end

    end

  end

end
