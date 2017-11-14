namespace :onetimer do

  # rake RAILS_ENV=development onetimer:generate_estimated_participation_amount_report

  task :generate_estimated_participation_amount_report => :environment do
    perform_amount_report_generation
  end

  # perform script to get summary for estimated participation amount for kyc confirm users
  #
  # * Author: Aman
  # * Date: 04/11/2017
  # * Reviewed By:
  #
  def perform_amount_report_generation
    @csv_data = {}
    failed_ued_ids = []

    UserKycDetail.find_in_batches(batch_size: 100) do |batched_records|
      ued_ids = []
      kyc_detail_obj = {}

      batched_records.each do |record|
        kyc_detail_obj[record.user_id] = record
        ued_ids << record.user_extended_detail_id
      end

      UserExtendedDetail.where(id: ued_ids).each do |ued|
        r = Aws::Kms.new('kyc', 'admin').decrypt(ued.kyc_salt)
        unless r.success?
          failed_ued_ids << ued.id
          next
        end

        kyc_salt_d = r.data[:plaintext]
        add_to_csv_data(kyc_detail_obj[ued.user_id], ued, kyc_salt_d)
      end

    end

    puts "failed_ued_ids => #{failed_ued_ids.inspect}"
    puts "\n\n\n\n"
    write_to_csv
    puts "\n\n\n\n"
  end

  # Add a row into csv_data
  #
  # * Author: Aman
  # * Date: 04/11/2017
  # * Reviewed By:
  #
  def add_to_csv_data(user_kyc_detail, ued, kyc_salt_d)
    decryptor_obj = LocalCipher.new(kyc_salt_d)

    estimated_amount = decryptor_obj.decrypt(ued.estimated_participation_amount).data[:plaintext].to_f
    country = decryptor_obj.decrypt(ued.country).data[:plaintext]
    kyc_confirm_date = Time.at(user_kyc_detail.kyc_confirmed_at).in_time_zone('Pacific Time (US & Canada)').to_date.to_s
    kyc_approval_status = user_kyc_detail.kyc_approved? ? 'approved' : (user_kyc_detail.kyc_denied? ? 'denied' : 'pending')
    proof_of_support = (user_kyc_detail.pos_bonus_percentage.to_i > 0) ? 1 : 0
    alt_bonus = user_kyc_detail.alternate_token_id_for_bonus.present? ? 1 : 0

    ethereum_address = decryptor_obj.decrypt(ued.ethereum_address).data[:plaintext]

    number_of_transactions = 0
    total_ether_wei_value = 0
    PurchaseLog.where(ethereum_address: ethereum_address).each do |pl|
      number_of_transactions += 1
      total_ether_wei_value += pl.ether_wei_value
    end

    purchased_amount = GlobalConstant::ConversionRate.wei_to_basic_unit_in_string(total_ether_wei_value)

    element = [
      estimated_amount,
      country,
      kyc_confirm_date,
      kyc_approval_status,
      proof_of_support,
      alt_bonus,
      purchased_amount,
      number_of_transactions
    ]
    @csv_data[kyc_confirm_date] ||= []
    @csv_data[kyc_confirm_date] << element
  end

  # writes data in needed format in console
  #
  # * Author: Aman
  # * Date: 04/11/2017
  # * Reviewed By:
  #
  def write_to_csv
    file_data = []
    file_data << headers
    @csv_data.each do |date, array_data|
      file_data += array_data.shuffle
    end

    file_data.each { |b| puts b.join(',') }
  end

  # Headers for column
  #
  # * Author: Aman
  # * Date: 04/11/2017
  # * Reviewed By:
  #
  def headers
    [
        'estimated_amount',
        'country',
        'kyc_confirm_date',
        'kyc_approval_status',
        'proof_of_support',
        'alt_bonus',
        'purchased_amount',
        'number_of_transactions'
    ]
  end

end