namespace :onetimer do

  # rake RAILS_ENV=development onetimer:generate_estimated_participation_amount_report
  task :generate_estimated_participation_amount_report => :environment do

    amount_array = []
    failed_ued_ids = []

    UserKycDetail.select("id, user_extended_detail_id").all.find_in_batches(batch_size: 100) do |batched_records|

      ued_ids = []

      batched_records.each do |record|
        ued_ids << record.user_extended_detail_id
      end

      UserExtendedDetail.select("id, kyc_salt, estimated_participation_amount").where(id: ued_ids).each do |ued|

        kyc_salt_e = ued.kyc_salt

        r = Aws::Kms.new('kyc', 'admin').decrypt(kyc_salt_e)
        unless r.success?
          failed_ued_ids << ued.id
          next
        end

        kyc_salt_d = r.data[:plaintext]

        amount_array << LocalCipher.new(kyc_salt_d)
          .decrypt(ued.estimated_participation_amount).data[:plaintext].to_f

      end

    end

    puts "failed_ued_ids => #{failed_ued_ids.inspect}"

    sleep(2)

    puts amount_array.shuffle

  end

end