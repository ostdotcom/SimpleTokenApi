module Ddb
  class Test

    def self.get_item
      Ddb::UserKycComparisonDetail.new({shard_id: 's1'}, {use_column_mapping: true}).
          get_item({
                       key: [{
                                 attribute: {
                                     user_extended_detail_id: 183
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
      Ddb::UserKycComparisonDetail.new({shard_id: 's1'}, {use_column_mapping: true}).scan()
    end

    def self.update_item
      Ddb::UserKycComparisonDetail.new({shard_id: 's1'}, {use_column_mapping: true}).update_item(
          {
              key: [{
                  attribute: {
                      user_extended_detail_id: 86
                  }

              }],
              set: [
                  {attribute: {
                      image_processing_status: "processed",
                  }
                  }],
              add: [
                  {attribute: {
                      kyc_auto_approved_status: 32
                  }}],
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