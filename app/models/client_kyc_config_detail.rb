class ClientKycConfigDetail < EstablishSimpleTokenClientDbConnection

  include ActivityChangeObserver

  serialize :residency_proof_nationalities, Array
  serialize :blacklisted_countries, Array

  # should always be a symbolized hash
  # {
  #     referral: {
  #         label: 'referral code',
  #         validation: {
  #             required: 1
  #         },
  #         data_type: 'text'
  #     }
  # }

  serialize :extra_kyc_fields, Hash

  after_commit :memcache_flush


  # Add kyc config row for client
  #
  # * Author: Aman
  # * Date: 08/02/2018
  # * Reviewed By:
  #
  def self.add_config(params)

    fail 'mandatory kyc fields missing' if !params[:kyc_fields].is_a?(Array) ||
        (GlobalConstant::ClientKycConfigDetail.mandatory_client_fields - params[:kyc_fields]).present?

    fail 'Invalid kyc fields' if (params[:kyc_fields] - ClientKycConfigDetail.kyc_fields_config.keys).present?

    fail 'Invalid kyc auto send status email fields' if (params[:auto_send_kyc_emails] - ClientKycConfigDetail.auto_send_kyc_emails_config.keys).present?

    fail 'Invalid blacklisted_countries' if !params[:blacklisted_countries].is_a?(Array)

    fail 'Invalid residency_proof_nationalities' if !params[:residency_proof_nationalities].is_a?(Array)

    kyc_field_bit_value = 0
    auto_status_email_bit_value = 0

    params[:kyc_fields].each do |field_name|
      kyc_field_bit_value += ClientKycConfigDetail.kyc_fields_config[field_name]
    end

    params[:auto_send_kyc_emails].each do |field_name|
      auto_status_email_bit_value += ClientKycConfigDetail.auto_send_kyc_emails_config[field_name]
    end


    ClientKycConfigDetail.create!(
        client_id: params[:client_id],
        kyc_fields: kyc_field_bit_value,
        residency_proof_nationalities: params[:residency_proof_nationalities].map(&:upcase),
        blacklisted_countries: params[:blacklisted_countries].map(&:upcase),
        extra_kyc_fields: params[:extra_kyc_fields].deep_symbolize_keys,
        auto_send_kyc_emails: auto_status_email_bit_value,
        source: params[:source]
    )

  end

  # Array of kyc fields for kyc form
  #
  # * Author: Aman
  # * Date: 08/02/2018
  # * Reviewed By:
  #
  # @returns [Array<Symbol>] returns Array of kyc fields bits set for client's kyc form
  #
  def kyc_fields_array
    @kyc_fields_array = ClientKycConfigDetail.get_bits_set_for_kyc_fields(kyc_fields)
  end

  # kyc fields config
  #
  # * Author: Aman
  # * Date: 08/02/2018
  # * Reviewed By:
  #
  def self.kyc_fields_config
    @kyc_fields_config ||= {
        GlobalConstant::ClientKycConfigDetail.first_name_kyc_field => 1,
        GlobalConstant::ClientKycConfigDetail.last_name_kyc_field => 2,
        GlobalConstant::ClientKycConfigDetail.birthdate_kyc_field => 4,
        GlobalConstant::ClientKycConfigDetail.street_address_kyc_field => 8,
        GlobalConstant::ClientKycConfigDetail.city_kyc_field => 16,
        GlobalConstant::ClientKycConfigDetail.state_kyc_field => 32,
        GlobalConstant::ClientKycConfigDetail.country_kyc_field => 64,
        GlobalConstant::ClientKycConfigDetail.postal_code_kyc_field => 128,
        GlobalConstant::ClientKycConfigDetail.ethereum_address_kyc_field => 256,
        GlobalConstant::ClientKycConfigDetail.document_id_number_kyc_field => 512,
        GlobalConstant::ClientKycConfigDetail.nationality_kyc_field => 1024,
        GlobalConstant::ClientKycConfigDetail.document_id_file_path_kyc_field => 2048,
        GlobalConstant::ClientKycConfigDetail.selfie_file_path_kyc_field => 4096,
        GlobalConstant::ClientKycConfigDetail.residence_proof_file_path_kyc_field => 8192,
        GlobalConstant::ClientKycConfigDetail.estimated_participation_amount_kyc_field => 16384,
        GlobalConstant::ClientKycConfigDetail.investor_proof_files_path_kyc_field => 32768
    }
  end


  def auto_send_kyc_approve_email?
    auto_send_kyc_emails_array.include?(GlobalConstant::ClientKycConfigDetail.send_approve_email)
  end

  def auto_send_kyc_deny_email?
    auto_send_kyc_emails_array.include?(GlobalConstant::ClientKycConfigDetail.send_deny_email)
  end

  def auto_send_kyc_report_issue_email?
    auto_send_kyc_emails_array.include?(GlobalConstant::ClientKycConfigDetail.send_report_issue_email)
  end

  def auto_send_kyc_emails_array
    ClientKycConfigDetail.get_bits_set_for_auto_send_kyc_emails(auto_send_kyc_emails)
  end

  def self.auto_send_kyc_emails_config
    @auto_send_kyc_emails_config ||= {
        GlobalConstant::ClientKycConfigDetail.send_approve_email => 1,
        GlobalConstant::ClientKycConfigDetail.send_deny_email => 2,
        GlobalConstant::ClientKycConfigDetail.send_report_issue_email => 4

    }
  end

  # Bitwise columns config
  #
  # * Author: Aman
  # * Date: 08/02/2018
  # * Reviewed By:
  #
  def self.bit_wise_columns_config
    @b_w_c_c ||= {
        kyc_fields: kyc_fields_config,
        auto_send_kyc_emails: auto_send_kyc_emails_config
    }
  end

  # Note : always include this after declaring bit_wise_columns_config method
  include BitWiseConcern

  private

  # Flush Memcache
  #
  # * Author: Aman
  # * Date: 08/02/2018
  # * Reviewed By:
  #
  def memcache_flush
    client_memcache_key = Client.get_memcache_key_object.key_template % {id: self.client_id}
    Memcache.delete(client_memcache_key)
    ClientSetting.flush_client_settings_cache(self.client_id)
  end

end