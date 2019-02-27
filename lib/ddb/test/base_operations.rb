module Ddb
  module Test
    class BaseOperations

      def self.raise_error_if_failed
        r = yield
        puts "=================== #{r.inspect} ========================"
        raise unless r.success?
      end

    end

  end
end