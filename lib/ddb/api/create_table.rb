module Ddb
  module Api
    class CreateTable < Api::Base
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
      # eg. of create_table
      # Ddb::Api::CreateTable.new(params: {
      #   attribute_definitions: [
      #     {
      #       attribute_name: "u_e_d_i_c_i",
      #       attribute_type: "S",
      #     },
      #     {
      #       attribute_name: "c_a",
      #       attribute_type: "N",
      #     },
      #   ],
      #   key_schema: [
      #     {
      #       attribute_name: "u_e_d_i_c_i",
      #       key_type: "HASH",
      #     },
      #     {
      #       attribute_name: "c_a",
      #       key_type: "RANGE",
      #     },
      #   ],
      #   provisioned_throughput: {
      #     read_capacity_units: 5,
      #     write_capacity_units: 5,
      #   },
      #   table_name: "development_s1_test_model",
      # }).perform
      #
      #
      #
      #
      #

      def perform
        ddb_client.create_table @params
      end

    end
  end
end

