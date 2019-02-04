module Ddb
  class Test

    def self.get_item
      r = Ddb::UserKycComparisonDetail.new({shard_id: 's1'}, {use_column_mapping: true}).
          get_item({
                       key: [{
                                 attribute: {
                                     :user_extended_detail_id => 99
                                 }
                             }]
                   })
    end

    def self.put_item
      new_item = []
      item = ::UserKycComparisonDetail.second_to_last
      item = item.attributes
      item.delete "id"
      item["created_at"] = item["created_at"].to_i
      item["updated_at"] = item["updated_at"].to_i

      item.each do |attr, val|
        new_item << {

            attribute: {
                "#{attr}".to_sym => val
            }
        }
      end
      r = Ddb::UserKycComparisonDetail.new({shard_id: 's1'}, {use_column_mapping: true}).put_item(item: new_item)
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
      #r_1 = Ddb::UserKycComparisonDetail.new({shard_id: 's1'}, {use_column_mapping: true}).scan(limit: 5, exclusive_start_key: r.data[:data][:last_evaluated_key])
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
              remove: [[:first_name_match_percent]],
              return_values: "UPDATED_OLD"
          })

    end


  end
end

#
# Ddb::UserKycComparisonDetail.new({shard_id: 's1'}, {use_column_mapping: true}).
#     get_item({
#                  key: [{
#                            attribute: {
#                                user_extended_detail_id: 17
#                            }
#                        }]
#              })