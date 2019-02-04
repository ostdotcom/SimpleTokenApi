module Ddb
  module Api
    class CreateTable < Base
      def initialize(params)
        super
      end


      # create table api call with retry mechanism
      #
      # * Author: mayur
      # * Date: 01/02/2019
      # * Reviewed By:
      #
      # @return [Result::Base]
      #

      def perform
        ddb_client.create_table @params
      end

    end
  end
end

