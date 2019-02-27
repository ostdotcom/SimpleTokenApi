module Ddb
  module Test
    class TestOperationsWithShortNames < BaseOperations
      def self.perform
        raise_error_if_failed { get_item }
        raise_error_if_failed {put_item}
        raise_error_if_failed{scan}
        raise_error_if_failed{ query}
        raise_error_if_failed{update_item}
        raise_error_if_failed{delete_item}
        raise_error_if_failed{batch_write}


      end


      def self.scan
        TestModel.new({shard_id: 's1'}, {use_column_mapping: false}).
            scan({limit: 5,
                  filter_conditions: {
                      conditions: [
                          {
                              attribute: {
                                  i_p_s: "1"
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


      # DDB response
      # {:items=>[{"d_d"=>{:s=>"{\"width\":\"212px\",\"height\":\"322px\"}", :n=>nil, :b=>nil, :ss=>nil, :ns=>nil, :bs=>nil, :m=>nil, :l=>nil, :null=>nil, :bool=>nil}, "u_e_d_i"=>{:s=>nil, :n=>"4", :b=>nil, :ss=>nil, :ns=>nil, :bs=>nil, :m=>nil, :l=>nil, :null=>nil, :bool=>nil}, "c_i"=>{:s=>nil, :n=>"76", :b=>nil, :ss=>nil, :ns=>nil, :bs=>nil, :m=>nil, :l=>nil, :null=>nil, :bool=>nil}, "u_e_d_i_c_i"=>{:s=>"4#76", :n=>nil, :b=>nil, :ss=>nil, :ns=>nil, :bs=>nil, :m=>nil, :l=>nil, :null=>nil, :bool=>nil}}], :count=>1, :scanned_count=>1, :last_evaluated_key=>nil, :consumed_capacity=>nil}
      def self.query
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
                                i_p_s: 1
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


      def self.delete_item
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
                    i_p_s: 1,
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


      def self.batch_write
        items = [
            [
                {:attribute => {:u_e_d_i_c_i => "10#100"}},
                {:attribute => {:c_a => 10000000}},
                {:attribute => {:u_e_d_i => 10}},
                {:attribute => {:c_i => 100}},
                {:attribute => {:l_i => "p_32#1"}},
                {:attribute => {:d_d => {:width => "212px", :height => "322px"}}},
                {:attribute => {:s_d => {:width => "212px", :height => "322px"}}},
                {:attribute => {:f_n_m_p => 54.0}},
                {:attribute => {:l_n_m_p => 432.0}},
                {:attribute => {:i_p_s => "1"}},
                {:attribute => {:k_a_a_s => 1}}
            ],

            [
                {:attribute => {:u_e_d_i_c_i => "20#200"}},
                {:attribute => {:c_a => 20000000}},
                {:attribute => {:u_e_d_i => 20}},
                {:attribute => {:c_i => 200}},
                {:attribute => {:l_i => "p_32#2"}},
                {:attribute => {:d_d => {:width => "21212px", :height => "322px"}}},
                {:attribute => {:s_d => {:width => "s212px", :height => "322px"}}},
                {:attribute => {:f_n_m_p => 54.0}},
                {:attribute => {:l_n_m_p => 432.0}},
                {:attribute => {:i_p_s => "2"}},
                {:attribute => {:k_a_a_s => 1}}


            ],

            [
                {:attribute => {:u_e_d_i_c_i => "30#300"}},
                {:attribute => {:c_a => 30000000}},
                {:attribute => {:u_e_d_i => 30}},
                {:attribute => {:c_i => 300}},
                {:attribute => {:l_i => "p_32#1"}},
                {:attribute => {:d_d => {:width => "21211px", :height => "322px"}}},
                {:attribute => {:s_d => {:width => "212px", :height => "322px"}}},
                {:attribute => {:f_n_m_p => 54.0}},
                {:attribute => {:l_n_m_p => 432.0}},
                {:attribute => {:i_p_s => "1"}},
                {:attribute => {:k_a_a_s => 1}}


            ],

            [
                {:attribute => {:u_e_d_i_c_i => "40#400"}},
                {:attribute => {:c_a => 40000000}},
                {:attribute => {:u_e_d_i => 40}},
                {:attribute => {:c_i => 400}},
                {:attribute => {:l_i => "p_322#1"}},
                {:attribute => {:d_d => {:width => "212px", :height => "322px"}}},
                {:attribute => {:s_d => {:width => "212px", :height => "322px"}}},
                {:attribute => {:f_n_m_p => 54.0}},
                {:attribute => {:l_n_m_p => 432.0}},
                {:attribute => {:i_p_s => "1"}},
                {:attribute => {:k_a_a_s => 1}}
            ]

        ]

        TestModel.new({shard_id: 's1'}, {use_column_mapping: false}).
            batch_write({items: items, return_consumed_capacity: "TOTAL", return_item_collection_metrics: "SIZE"})
      end


      def self.put_item
        item = [{:attribute => {:u_e_d_i_c_i => "7#43"}},
                {:attribute => {:c_a => 12233445}},
                {:attribute => {:u_e_d_i => 2}},
                {:attribute => {:c_i => 43}},
                {:attribute => {:l_i => "p_32#2"}},
                {:attribute => {:d_d => {:width => "212px", :height => "322px"}}},
                {:attribute => {:s_d => {:width => "212px", :height => "322px"}}},
                {:attribute => {:f_n_m_p => 54.0}},
                {:attribute => {:l_n_m_p => 432.0}},
                {:attribute => {:i_p_s => "2"}},
                {:attribute => {:k_a_a_s => 1}}]
        TestModel.new({shard_id: 's1'}, {use_column_mapping: false}).put_item(item: item, return_values: "ALL_OLD")
      end

      def self.get_item
        r = TestModel.new({shard_id: 's1'}, {use_column_mapping: false}).
            get_item({
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

                     })
      end


    end
  end
end
