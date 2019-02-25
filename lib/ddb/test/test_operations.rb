module Ddb
  module Test
    class TestOperations

      # todo:ddb - test for array and hash and log the response
      def self.get_item
        r = TestModel.new({shard_id: 's1'}, {use_column_mapping: true}).
            get_item({
                         key: [{
                                   attribute: {
                                       user_extended_detail_id: 4,
                                       client_id: 76
                                   }
                               },
                               {
                                   attribute: {
                                       created_at: 22233445
                                   }
                               },

                         ],
                         #projection_expression: [[:user_extended_detail_id, :client_id], [:client_id], [:document_dimensions]],
                         consistent_read: true,
                         return_consumed_capacity: "TOTAL"
                     })
      end


      def self.get_item_without_mapping
        r = TestModel.new({shard_id: 's1'}, {use_column_mapping: false}).
            get_item({
                         key: [{
                                   attribute: {
                                       u_e_d_i_c_i: "2#43"
                                   }
                               },
                               {
                                   attribute: {
                                       c_a: 12233445
                                   }
                               }],

                     })
      end

      def self.put_item_without_mapping
        item = [{:attribute => {:u_e_d_i_c_i => "2#43"}},
                {:attribute => {:c_a => 12233445}},
                {:attribute => {:u_e_d_i => 2}},
                {:attribute => {:c_i => 43}},
                {:attribute => {:l_i => "p_32#failed"}},
                {:attribute => {:d_d => {:width => "212px", :height => "322px"}}},
                {:attribute => {:s_d => {:width => "212px", :height => "322px"}}},
                {:attribute => {:f_n_m_p => 54.0}},
                {:attribute => {:l_n_m_p => 432.0}},
                {:attribute => {:i_p_s => "failed"}},
                {:attribute => {:k_a_a_s => 1}}]
        TestModel.new({shard_id: 's1'}, {use_column_mapping: false}).put_item(item: item, return_values: "ALL_OLD")
      end


      def self.put_item
        item = [{:attribute => {:user_extended_detail_id => 4, :client_id => 76}},
                {:attribute => {:created_at => 22233445}},
                {:attribute => {:user_extended_detail_id => 4}},
                {:attribute => {:client_id => 76}},
                {:attribute => {:lock_id => "p_21", :image_processing_status => "processed"}},
                {:attribute => {:document_dimensions => {:width => "212px", :height => "322px"}}},
                {:attribute => {:selfie_dimensions => {:width => "212px", :height => "322px"}}},
                {:attribute => {:first_name_match_percent => 20.0}},
                {:attribute => {:last_name_match_percent => 45.0}},
                {:attribute => {:image_processing_status => "processed"}},
                {:attribute => {:kyc_auto_approved_status => 1}}]
        TestModel.new({shard_id: 's1'}, {use_column_mapping: true}).put_item(item: item, return_item_collection_metrics: "SIZE")
      end

      def self.scan
        TestModel.new({shard_id: 's1'}, {use_column_mapping: true}).
            scan({limit: 5, filter_conditions: {
                conditions: [
                    {
                        attribute: {
                            image_processing_status: "processing"
                        },
                        operator: "="
                    },
                    {
                        attribute: {
                            client_id: 80
                        },
                        operator: "<"
                    }

                ],
                logical_operator: "AND",
            },
                  projection_expression: [[:user_extended_detail_id, :client_id], [:client_id], [:document_dimensions]]
                 }
            )
      end

      def self.scan_all
        TestModel.new({shard_id: 's1'}, {use_column_mapping: true}).
            scan({#limit: 5
                  #projection_expression: [[:user_extended_detail_id, :client_id], [:client_id], [:document_dimensions]]
                  consistent_read: true
                 }
            )
      end


      def self.scan_wo_mapping
        TestModel.new({shard_id: 's1'}, {use_column_mapping: false}).
            scan({limit: 5,
                  filter_conditions: {
                      conditions: [
                          {
                              attribute: {
                                  i_p_s: "processing"
                              },
                              operator: "="
                          },
                          {
                              attribute: {
                                  c_i: 80
                              },
                              operator: "<"
                          }

                      ],
                      logical_operator: "AND",
                  },
                  projection_expression: [:u_e_d_i_c_i, :c_i, :d_d, :u_e_d_i]
                 }
            )
      end

      def self.query_wo_mapping
        TestModel.new({shard_id: 's1'}, {use_column_mapping: false}).query(
            {
                key_conditions: [
                    {
                        attribute: {
                            u_e_d_i_c_i: "4#76",
                        },
                        operator: "="
                    }
                ],
                filter_conditions: {
                    conditions: [
                        {
                            attribute: {
                                i_p_s: "processing"
                            },
                            operator: "="
                        }

                    ],
                    logical_operator: "AND"
                },
                limit: 2,
                return_consumed_capacity: "TOTAL",
                projection_expression: [:u_e_d_i_c_i, :c_i, :d_d, :u_e_d_i]
            }
        )
      end


      def self.query
        TestModel.new({shard_id: 's1'}, {use_column_mapping: true}).query(
            {
                key_conditions: [
                    {
                        attribute: {
                            user_extended_detail_id: 4,
                            client_id: 76
                        },
                        operator: "="
                    }
                ],
                filter_conditions: {
                    conditions: [
                        {
                            attribute: {
                                image_processing_status: "processing"
                            },
                            operator: "="
                        }

                    ],
                    logical_operator: "AND"
                },
                limit: 2,
                return_consumed_capacity: "TOTAL",
                projection_expression: [[:user_extended_detail_id, :client_id], [:client_id], [:document_dimensions]]
            }
        )
      end


      def self.delete_item
        r = TestModel.new({shard_id: 's1'}, {use_column_mapping: true}).
            delete_item({
                            key: [{
                                      attribute: {
                                          user_extended_detail_id: 2,
                                          client_id: 43
                                      }
                                  },
                                  {
                                      attribute: {
                                          created_at: 12233445
                                      }
                                  },

                            ],
                            return_values: "ALL_OLD"
                        })

      end


      def self.delete_item_wo_mapping
        r = TestModel.new({shard_id: 's1'}, {use_column_mapping: false}).
            delete_item({
                            key: [{
                                      attribute: {
                                          :u_e_d_i_c_i => "4#76"
                                      }
                                  },
                                  {
                                      attribute: {
                                          c_a: 22233445
                                      }
                                  },

                            ],
                            return_values: "ALL_OLD"
                        })

      end


      def self.update_item
        TestModel.new({shard_id: 's1'}, {use_column_mapping: true}).update_item(
            {
                key: [{
                          attribute: {
                              user_extended_detail_id: 4,
                              client_id: 76
                          }
                      },
                      {
                          attribute: {
                              created_at: 22233445
                          }
                      }],
                remove: [[:selfie_dimensions]],
                set: [{attribute: {
                    image_processing_status: "processed",
                }}
                ],
                add: [
                    {attribute: {
                        kyc_auto_approved_status: 32
                    }}
                ],
                return_values: "UPDATED_OLD"
            })
      end


      def self.update_item_wo_mapping
        TestModel.new({shard_id: 's1'}, {use_column_mapping: false}).update_item(
            {
                key: [{
                          attribute: {
                              u_e_d_i_c_i: "4#76"
                          }
                      },
                      {
                          attribute: {
                              c_a: 22233445
                          }
                      }],
                remove: [:d_i_n_m_p],
                set: [{attribute: {
                    i_p_s: "processed_1",
                }}
                ],
                add: [
                    {attribute: {
                        k_a_a_s: 32
                    }}
                ],
                return_values: "UPDATED_OLD"
            })
      end



      def self.batch_write_wo_mapping
        items = [
            [
                {:attribute => {:u_e_d_i_c_i => "10#100"}},
                {:attribute => {:c_a => 10000000}},
                {:attribute => {:u_e_d_i => 10}},
                {:attribute => {:c_i => 100}},
                {:attribute => {:l_i => "p_32#failed"}},
                {:attribute => {:d_d => {:width => "212px", :height => "322px"}}},
                {:attribute => {:s_d => {:width => "212px", :height => "322px"}}},
                {:attribute => {:f_n_m_p => 54.0}},
                {:attribute => {:l_n_m_p => 432.0}},
                {:attribute => {:i_p_s => "failed"}},
                {:attribute => {:k_a_a_s => 1}}
            ],

            [
                {:attribute => {:u_e_d_i_c_i => "20#200"}},
                {:attribute => {:c_a => 20000000}},
                {:attribute => {:u_e_d_i => 20}},
                {:attribute => {:c_i => 200}},
                {:attribute => {:l_i => "p_32#cold"}},
                {:attribute => {:d_d => {:width => "21212px", :height => "322px"}}},
                {:attribute => {:s_d => {:width => "s212px", :height => "322px"}}},
                {:attribute => {:f_n_m_p => 54.0}},
                {:attribute => {:l_n_m_p => 432.0}},
                {:attribute => {:i_p_s => "cold"}},
                {:attribute => {:k_a_a_s => 1}}


            ],

            [
                {:attribute => {:u_e_d_i_c_i => "30#300"}},
                {:attribute => {:c_a => 30000000}},
                {:attribute => {:u_e_d_i => 30}},
                {:attribute => {:c_i => 300}},
                {:attribute => {:l_i => "p_32#yo"}},
                {:attribute => {:d_d => {:width => "21211px", :height => "322px"}}},
                {:attribute => {:s_d => {:width => "212px", :height => "322px"}}},
                {:attribute => {:f_n_m_p => 54.0}},
                {:attribute => {:l_n_m_p => 432.0}},
                {:attribute => {:i_p_s => "yo"}},
                {:attribute => {:k_a_a_s => 1}}


            ],

            [
                {:attribute => {:u_e_d_i_c_i => "40#400"}},
                {:attribute => {:c_a => 40000000}},
                {:attribute => {:u_e_d_i => 40}},
                {:attribute => {:c_i => 400}},
                {:attribute => {:l_i => "p_322#kya_baat_hai"}},
                {:attribute => {:d_d => {:width => "212px", :height => "322px"}}},
                {:attribute => {:s_d => {:width => "212px", :height => "322px"}}},
                {:attribute => {:f_n_m_p => 54.0}},
                {:attribute => {:l_n_m_p => 432.0}},
                {:attribute => {:i_p_s => "kya_baat_hai"}},
                {:attribute => {:k_a_a_s => 1}}
            ]

        ]

        TestModel.new({shard_id: 's1'}, {use_column_mapping: false}).
            batch_write({items: items, return_consumed_capacity: "TOTAL", return_item_collection_metrics: "SIZE"})
      end


      def self.batch_write
        items = [
            [{:attribute => {:user_extended_detail_id => 50, :client_id => 500}},
             {:attribute => {:created_at => 50000000}},
             {:attribute => {:user_extended_detail_id => 50}},
             {:attribute => {:client_id => 500}},
             {:attribute => {:lock_id => "p_50", :image_processing_status => "tilda"}},
             {:attribute => {:document_dimensions => {:width => "500px", :height => "5000px"}}},
             {:attribute => {:selfie_dimensions => {:width => "200px", :height => "2000px"}}},
             {:attribute => {:first_name_match_percent => 20.0}},
             {:attribute => {:last_name_match_percent => 45.0}},
             {:attribute => {:image_processing_status => "tilda"}},
             {:attribute => {:kyc_auto_approved_status => 1}}
            ],

            [{:attribute => {:user_extended_detail_id => 60, :client_id => 600}},
             {:attribute => {:created_at => 60000000}},
             {:attribute => {:user_extended_detail_id => 60}},
             {:attribute => {:client_id => 600}},
             {:attribute => {:lock_id => "p_60", :image_processing_status => "Samm"}},
             {:attribute => {:document_dimensions => {:width => "600px", :height => "6000px"}}},
             {:attribute => {:selfie_dimensions => {:width => "600px", :height => "6000px"}}},
             {:attribute => {:first_name_match_percent => 20.0}},
             {:attribute => {:last_name_match_percent => 45.0}},
             {:attribute => {:image_processing_status => "Samm"}},
             {:attribute => {:kyc_auto_approved_status => 1}}
            ],
            [{:attribute => {:user_extended_detail_id => 70, :client_id => 700}},
             {:attribute => {:created_at => 70000000}},
             {:attribute => {:user_extended_detail_id => 70}},
             {:attribute => {:client_id => 700}},
             {:attribute => {:lock_id => "p_70", :image_processing_status => "yoo"}},
             {:attribute => {:document_dimensions => {:width => "500px", :height => "5000px"}}},
             {:attribute => {:selfie_dimensions => {:width => "200px", :height => "2000px"}}},
             {:attribute => {:first_name_match_percent => 20.0}},
             {:attribute => {:last_name_match_percent => 45.0}},
             {:attribute => {:image_processing_status => "yoo"}},
             {:attribute => {:kyc_auto_approved_status => 1}}
            ],
            [{:attribute => {:user_extended_detail_id => 80, :client_id => 800}},
             {:attribute => {:created_at => 80000000}},
             {:attribute => {:user_extended_detail_id => 80}},
             {:attribute => {:client_id => 800}},
             {:attribute => {:lock_id => "p_50", :image_processing_status => "dsd"}},
             {:attribute => {:document_dimensions => {:width => "800px", :height => "5000px"}}},
             {:attribute => {:selfie_dimensions => {:width => "200px", :height => "2000px"}}},
             {:attribute => {:first_name_match_percent => 20.0}},
             {:attribute => {:last_name_match_percent => 45.0}},
             {:attribute => {:image_processing_status => "dsd"}},
             {:attribute => {:kyc_auto_approved_status => 1}}
            ]

        ]

        TestModel.new({shard_id: 's1'}, {use_column_mapping: true}).
            batch_write({items: items, return_consumed_capacity: "TOTAL", return_item_collection_metrics: "SIZE"})
      end


    end
  end
end