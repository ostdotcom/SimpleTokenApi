namespace :onetimer do

  # rake RAILS_ENV=development onetimer:generate_estimated_participation_amount_report

  task :generate_estimated_participation_amount_report => :environment do

    init_vars

    fetch_data

    puts "@failed_kms_decrypt_ued_ids => #{@failed_kms_decrypt_ued_ids.inspect}"
    puts "\n\n\n\n"

    generate_csv_data

    print_as_csv

    puts "\n\n\n\n"

  end

  # init vars
  #
  # * Author: Kedar, Alpesh
  # * Date: 15/11/2017
  # * Reviewed By:
  #
  def init_vars
    @ethereum_addr_case_data_map = {}
    @case_data_by_date_map = {}
    @failed_kms_decrypt_ued_ids = []
  end

  # fetch data
  #
  # * Author: Kedar, Alpesh
  # * Date: 15/11/2017
  # * Reviewed By:
  #
  # Sets @failed_kms_decrypt_ued_ids
  #
  def fetch_data

    UserKycDetail.find_in_batches(batch_size: 100) do |batched_records|
      batch_ued_ids = []
      user_id_to_ukd_map = {}

      batched_records.each do |record|
        user_id_to_ukd_map[record.user_id] = record
        batch_ued_ids << record.user_extended_detail_id
      end

      UserExtendedDetail.where(id: batch_ued_ids).each do |user_extended_detail|
        user_kyc_detail = user_id_to_ukd_map[user_extended_detail.user_id]

        r = Aws::Kms.new('kyc', 'admin').decrypt(user_extended_detail.kyc_salt)
        unless r.success?
          @failed_kms_decrypt_ued_ids << user_extended_detail.id
          next
        end

        kyc_salt_d = r.data[:plaintext]

        case_data = generate_case_data(kyc_salt_d, user_extended_detail, user_kyc_detail)

        populate_ethereum_addr_case_data_map(case_data)
      end

    end

  end

  # populate ethereum addr case data map
  #
  # * Author: Kedar, Alpesh
  # * Date: 15/11/2017
  # * Reviewed By:
  #
  # @param [Hash] case_data
  #
  # Sets @ethereum_addr_case_data_map
  #
  def populate_ethereum_addr_case_data_map(case_data)
    ethereum_address = case_data[:ethereum_address]

    if @ethereum_addr_case_data_map[ethereum_address.downcase].present?
      return if case_data[:kyc_approval_status] != 'approved'
      if @ethereum_addr_case_data_map[ethereum_address.downcase][:kyc_approval_status] == 'approved'
        fail "#{ethereum_address} is approved for 2 KYC"
      end
    end

    @ethereum_addr_case_data_map[ethereum_address.downcase] = case_data

  end

  # generate case data
  #
  # * Author: Kedar, Alpesh
  # * Date: 15/11/2017
  # * Reviewed By:
  #
  # @param [String] kyc_salt_d
  # @param [UserExtendedDetail] user_extended_detail
  # @param [UserKycDetail] user_kyc_detail
  #
  # @return [Hash]
  #
  def generate_case_data(kyc_salt_d, user_extended_detail, user_kyc_detail)
    decryptor_obj = LocalCipher.new(kyc_salt_d)

    estimated_amount = decryptor_obj.decrypt(user_extended_detail.estimated_participation_amount).data[:plaintext].to_f
    country = decryptor_obj.decrypt(user_extended_detail.country).data[:plaintext]
    kyc_confirm_date = Time.at(user_kyc_detail.kyc_confirmed_at).in_time_zone('Pacific Time (US & Canada)').to_date.to_s
    kyc_approval_status = user_kyc_detail.kyc_approved? ? 'approved' : (user_kyc_detail.kyc_denied? ? 'denied' : 'pending')
    proof_of_support = (user_kyc_detail.pos_bonus_percentage.to_i > 0) ? 1 : 0
    alt_bonus = user_kyc_detail.alternate_token_id_for_bonus.present? ? 1 : 0

    ethereum_address = decryptor_obj.decrypt(user_extended_detail.ethereum_address).data[:plaintext]

    number_of_transactions = 0
    total_ether_wei_value = 0
    PurchaseLog.where(ethereum_address: ethereum_address).each do |pl|
      number_of_transactions += 1
      total_ether_wei_value += pl.ether_wei_value
    end

    purchased_amount = GlobalConstant::ConversionRate.wei_to_basic_unit_in_string(total_ether_wei_value)

    {
      ethereum_address: ethereum_address,
      estimated_amount: estimated_amount,
      country: country,
      kyc_confirm_date: kyc_confirm_date,
      kyc_approval_status: kyc_approval_status,
      proof_of_support: proof_of_support,
      alt_bonus: alt_bonus,
      purchased_amount: purchased_amount,
      number_of_transactions: number_of_transactions
    }
  end

  # generate csv data
  #
  # * Author: Kedar, Alpesh
  # * Date: 15/11/2017
  # * Reviewed By:
  #
  # Sets @case_data_by_date_map
  #
  def generate_csv_data

    @ethereum_addr_case_data_map.each do |_, data|
      kyc_confirm_date = data[:kyc_confirm_date]
      @case_data_by_date_map[kyc_confirm_date] ||= []

      @case_data_by_date_map[kyc_confirm_date] << get_csv_row_element(data)
    end

  end

  # print as csv
  #
  # * Author: Kedar, Alpesh
  # * Date: 15/11/2017
  # * Reviewed By:
  #
  def print_as_csv
    file_data = []
    file_data << headers
    @case_data_by_date_map.each do |_, elements|
      file_data += elements.shuffle
    end

    file_data.each do |element|
      puts element.join(',')
    end
  end

  # Headers
  #
  # * Author: Kedar, Alpesh
  # * Date: 15/11/2017
  # * Reviewed By:
  #
  # @return [Array]
  #
  def headers
    @headers ||= begin
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

  # Get csv row element
  #
  # * Author: Kedar, Alpesh
  # * Date: 15/11/2017
  # * Reviewed By:
  #
  # @return [Array]
  #
  def get_csv_row_element(data)
    element = []

    headers.each do |h|
      element << data[h.to_sym]
    end

    element
  end

end