module Ddb
  module Test
    class TestOperations

      def self.get_item
        r = TestModel.new({shard_id: 's1'}, {use_column_mapping: true}).
            get_item({
                         key: [{
                                   attribute: {
                                       user_extended_detail_id: 2,
                                       client_id: 88
                                   }
                               },
                               {
                                   attribute: {
                                       created_at: 12233445
                                   }
                               },

                         ]
                     })
      end


      def self.get_item_without_mapping
        r = TestModel.new({shard_id: 's1'}, {use_column_mapping: false}).
            get_item({
                         key: [{
                                   attribute: {
                                       u_e_d_i_c_i: "2#88",
                                   }
                               },
                               {
                                   attribute: {
                                       c_a: 12233445
                                   }
                               },

                         ]
                     })
      end

      def self.put_item
        # new_item = []
        # item = ::UserKycComparisonDetail.second
        # item = item.attributes
        # item.delete "id"
        # item["created_at"] = item["created_at"].to_i
        # item["updated_at"] = item["updated_at"].to_i
        #
        # item.each do |attr, val|
        #   new_item << {
        #
        #       attribute: {
        #           "#{attr}".to_sym => val
        #       }
        #   }
        # end
        # r = Ddb::UserKycComparisonDetail.new({shard_id: 's1'}, {use_column_mapping: true}).put_item(item: new_item)
        #


        item = [
            {

                attribute: {
                    user_extended_detail_id: 2,
                    client_id: 88
                }
            },
            {

                attribute: {
                    created_at: 12233445
                }
            },
            {

                attribute: {
                    user_extended_detail_id: 1,
                }
            },
            {

                attribute: {
                    client_id: 88
                }
            },
            {

                attribute: {
                    lock_id: "p_31",
                    image_processing_status: "processing"
                }
            },
            {

                attribute: {
                    document_dimensions: {width: "212px", height: "322px" }
                }
            },
            {

                attribute: {
                    selfie_dimensions: {width: "212px", height: "322px" }
                }
            },
            {

                attribute: {
                    first_name_match_percent: 20.00,
                }
            },
            {

                attribute: {
                    last_name_match_percent: 45.00
                }
            },
            {

                attribute: {
                    image_processing_status: "processing"
                }
            },
            {

                attribute: {
                    kyc_auto_approved_status: 1
                }
            }
        ]
        TestModel.new({shard_id: 's1'}, {use_column_mapping: true}).put_item(item: item)

      end

      def self.delete_item
        r = Ddb::UserKycComparisonDetail.new({shard_id: 's1'}, {use_column_mapping: true}).
            delete_item({
                            key: [{
                                      attribute: {
                                          :user_extended_detail_id => 99
                                      }
                                  }]
                        })

      end


      def self.scan
        r = Ddb::UserKycComparisonDetail.new({shard_id: 's1'}, {use_column_mapping: true}).scan(limit: 5, filter_conditions: {
            conditions: [
                {
                    attribute: {
                        image_processing_status: "unprocessed"
                    },
                    operator: "="
                }

            ],
            logical_operator: "AND"
        })
        puts "rrrr #{r.inspect}"
        r_1 = Ddb::UserKycComparisonDetail.new({shard_id: 's1'}, {use_column_mapping: true}).scan(limit: 5, exclusive_start_key: r.data[:data][:last_evaluated_key])
      end

      def self.query
        Ddb::UserKycComparisonDetail.new({shard_id: 's1'}, {use_column_mapping: true}).query(
            {
                key_conditions: [
                    {
                        attribute: {
                            user_extended_detail_id: 90
                        },
                        operator: "="
                    }
                ],
                filter_conditions: {
                    conditions: [
                        {
                            attribute: {
                                image_processing_status: "processed"
                            },
                            operator: "="
                        }

                    ],
                    logical_operator: "AND"
                },
                limit: 1
            }
        )
      end

      def self.update_item
        Ddb::UserKycComparisonDetail.new({shard_id: 's1'}, {use_column_mapping: true}).update_item(
            {
                key: [{
                          attribute: {
                              user_extended_detail_id: 90
                          }
                      }],
                remove: [[:last_name_match_percent]],
                return_values: "UPDATED_OLD"
            })

      end
    end
  end
end