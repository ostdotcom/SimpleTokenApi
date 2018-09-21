module ReportJob

  class Kyc < Base

    IMAGES_URL_EXPIRY_TIMESTAMP_INTERVAL = 7.days.to_i

    # Perform
    #
    # * Author: Aman
    # * Date: 18/04/2018
    # * Reviewed By:
    #
    # @param [Hash] params
    #
    def perform(params)
      super
    end

    private

    # Init params
    #
    # * Author: Aman
    # * Date: 18/04/2018
    # * Reviewed By:
    #
    # @param [Hash] params
    #
    def init_params(params)
      super
      @client_kyc_config = nil
    end

    # fetch csv_report_job & admin obj
    #
    # * Author: Aman
    # * Date: 18/04/2018
    # * Reviewed By:
    #
    # Sets @client_kyc_config
    #
    def fetch_details
      super
      @client_kyc_config = ClientKycConfigDetail.get_from_memcache(@client_id)
    end

    # validate
    #
    # * Author: Aman
    # * Date: 18/04/2018
    # * Reviewed By:
    #
    # @return [Result::Base]
    #
    def validate
      r = super
      return r unless r.success?

      return error_with_data(
          'rj_k_v_1',
          'Invalid Report type identified',
          'Invalid Report type identified',
          GlobalConstant::ErrorAction.default,
          {}
      ) if @csv_report_job.report_type != GlobalConstant::CsvReportJob.kyc_report_type

      success
    end


    def get_data_from_db
      offset = 0

      while (true)
        user_extended_detail_ids = []
        user_ids = []

        user_kyc_details = user_kyc_detail_model_query.limit(MYSQL_BATCH_SIZE).offset(offset).all
        break if user_kyc_details.blank?

        user_kyc_details.each do |user_kyc_detail|
          user_extended_detail_ids << user_kyc_detail.user_extended_detail_id
          user_ids << user_kyc_detail.user_id
        end

        users = ::User.where(client_id: @client_id, id: user_ids).all.index_by(&:id)
        user_extended_details = ::UserExtendedDetail.where(id: user_extended_detail_ids).all.index_by(&:id)

        user_kyc_details.each do |user_kyc_detail|
          user = users[user_kyc_detail.user_id]
          user_extended_detail = user_extended_details[user_kyc_detail.user_extended_detail_id]
          user_data = get_user_data(user, user_kyc_detail, user_extended_detail)
          yield(user_data)
        end

        offset += MYSQL_BATCH_SIZE
      end

      return offset > 0
    end

    def user_kyc_detail_model_query
      @user_kyc_detail_model_query ||= begin
        ar_relation = UserKycDetail.where(client_id: @client_id).active_kyc
        ar_relation = ar_relation.filter_by(@filters)
        ar_relation = ar_relation.sorting_by(@sortings)
        ar_relation
      end
    end

    def get_user_data(user, user_kyc_detail, user_extended_detail)
      kyc_salt_e = user_extended_detail.kyc_salt
      r = Aws::Kms.new('kyc', 'admin').decrypt(kyc_salt_e)
      throw 'unable to decrypt salt from kms' unless r.success?
      kyc_salt_d = r.data[:plaintext]
      local_cipher_obj = LocalCipher.new(kyc_salt_d)

      user_data = {
          email: user.email,
          submitted_at: Time.at(user_extended_detail.created_at).strftime("%d/%m/%Y %H:%M %z"), # test time with zone
          admin_status: user_kyc_detail.admin_status,
          cynopsis_status: user_kyc_detail.cynopsis_status
      }
      user_data[:whitelist_status] = user_kyc_detail.whitelist_status if other_kyc_fields.include?('whitelist_status')

      kyc_form_fields.each do |field_name|
        if GlobalConstant::ClientKycConfigDetail.unencrypted_fields.include?(field_name)
          user_data[field_name.to_sym] = user_extended_detail[field_name]
        elsif GlobalConstant::ClientKycConfigDetail.encrypted_fields.include?(field_name)

          if GlobalConstant::ClientKycConfigDetail.non_mandatory_fields.include?(field_name) && user_extended_detail[field_name].blank?
            if field_name == GlobalConstant::ClientKycConfigDetail.investor_proof_files_path_kyc_field
              for i in 1..GlobalConstant::ClientKycConfigDetail.max_number_of_investor_proofs_allowed
                user_data["#{field_name}_#{i}".to_sym] = nil
              end
            else
              user_data[field_name.to_sym] = nil
            end
            next
          end

          decrypted_data = local_cipher_obj.decrypt(user_extended_detail[field_name]).data[:plaintext]

          if GlobalConstant::ClientKycConfigDetail.image_url_fields.include?(field_name)
            if field_name == GlobalConstant::ClientKycConfigDetail.investor_proof_files_path_kyc_field
              for i in 1..GlobalConstant::ClientKycConfigDetail.max_number_of_investor_proofs_allowed
                user_data["#{field_name}_#{i}".to_sym] = get_image_url(decrypted_data[i - 1])
              end
            else
              user_data[field_name.to_sym] = get_image_url(decrypted_data)
            end
          else
            user_data[field_name.to_sym] = decrypted_data
          end

        else
          throw "invalid kyc field-#{field_name}"
        end
      end

      return user_data
    end

    def get_image_url(s3_path)
      return nil unless s3_path.present?
      s3_manager_obj.get_signed_url_for(GlobalConstant::Aws::Common.kyc_bucket, s3_path, {expires_in: IMAGES_URL_EXPIRY_TIMESTAMP_INTERVAL})
    end

    def kyc_form_fields
      @kyc_fields ||= @client_kyc_config.kyc_fields_array
    end

    def headers_for_form_fields
      @headers_for_form_fields ||= begin
        fields = kyc_form_fields
        if fields.include?(GlobalConstant::ClientKycConfigDetail.investor_proof_files_path_kyc_field)
          fields = fields - [GlobalConstant::ClientKycConfigDetail.investor_proof_files_path_kyc_field]
          for i in 1..GlobalConstant::ClientKycConfigDetail.max_number_of_investor_proofs_allowed
            fields << "#{GlobalConstant::ClientKycConfigDetail.investor_proof_files_path_kyc_field}_#{i}"
          end
        end
        fields
      end
    end

    def other_kyc_fields
      @kyc_status_fields ||=
          begin
            fields = ['admin_status', 'cynopsis_status', 'submitted_at']
            fields << 'whitelist_status' if @client.is_whitelist_setup_done?
            fields
          end
    end

    def csv_headers
      ['email'] + other_kyc_fields + headers_for_form_fields
    end

  end
end
