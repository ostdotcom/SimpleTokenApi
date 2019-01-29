namespace :onetimer do
  LIMIT = 2
  task :sql_ddb_migration => :environment do

    @final_id = UserKycComparisonDetail.where(image_processing_status: GlobalConstant::ImageProcessing.unprocessed_image_process_status).first.id
    offset = 0


    def create_table
      params = {
          table_name: 'development_s1_user_kyc_comparison_details',
          key_schema: [
              {
                  attribute_name: 'u_e_d_i',
                  key_type: 'HASH' #Partition key
              }
          ],
          attribute_definitions: [
              {
                  attribute_name: 'u_e_d_i',
                  attribute_type: 'N'
              }
          ],
          provisioned_throughput: {
              read_capacity_units: 10,
              write_capacity_units: 10
          }
      }
      r = Ddb::Api::CreateTable.new(params)
      puts "==========**********response**********==========#{r.data}"
    end

    create_table

    def migration(offset)
      u_k_c_ds = UserKycComparisonDetail.where("id < ?", @final_id).limit(LIMIT).offset(offset)
      return nil if u_k_c_ds.blank?
      insert_in_ddb = []
      u_k_c_ds.each do |ukcd|
        item = ukcd.attributes
        item[:created_at] = item[:created_at].to_i
        item[:updated_at] = item[:updated_at].to_i
        insert_in_ddb << {put_request: {item: item}}
      end
      Ddb::UserKycComparisonDetail.new({shard_id: 's1'}, {use_column_mapping: true}).batch_write(insert_in_ddb)
    end

    while true do
      r = migration(offset)
      break unless r
      offset += LIMIT
    end

  end

end
