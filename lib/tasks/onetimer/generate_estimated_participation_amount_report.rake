namespace :onetimer do

  # rake RAILS_ENV=development onetimer:generate_estimated_participation_amount_report
  task :generate_estimated_participation_amount_report => :environment do

    amount_array = []
    failed_user_ids = []

    UserKycDetail.all.find_in_batches(batch_size: 100) do |batched_records|

      ued_ids = []

      batched_records.each do |record|
        ued_ids << record.user_extended_detail_id
      end

      UserExtendedDetail.where(id: ued_ids).each do |ued|

        kyc_salt_e = ued.kyc_salt

        r = Aws::Kms.new('kyc', 'admin').decrypt(kyc_salt_e)
        unless r.success?
          failed_user_ids << ued.user_id
          next
        end

        kyc_salt_d = r.data[:plaintext]

        amount_array << LocalCipher.new(kyc_salt_d)
          .decrypt(ued.estimated_participation_amount).data[:plaintext].to_f

      end

    end

    amount_array.shuffle.each do |amount|
      puts amount
    end

  end

end