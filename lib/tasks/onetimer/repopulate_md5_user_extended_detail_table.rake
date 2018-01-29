namespace :onetimer do

  # rake RAILS_ENV=development onetimer:repopulate_md5_user_extended_detail_table user_ids=13,18,11001,11071,2,11041,11056,11060
  task :repopulate_md5_user_extended_detail_table => :environment do

    # initialize
    #
    # * Author: Aman
    # * Date: 30/10/2017
    # * Reviewed By: Abhay
    #
    def initialize
      @run_role = 'admin'
      @run_purpose = 'kyc'
      @result = {success: [], failure: []}
    end

    # perform
    #
    # * Author: Aman
    # * Date: 30/10/2017
    # * Reviewed By: Abhay
    #
    def perform
      ar_query = UserExtendedDetail
      if @user_ids.present?
        ar_query = ar_query.where(user_id: @user_ids)
      end

      ar_query.find_in_batches(batch_size: 50) do |batches|
        batches.each do |user_extended_detail|
          begin

            kyc_salt_d = decrypt_kyc_salt(user_extended_detail.kyc_salt)
            decryptor_obj = LocalCipher.new(kyc_salt_d)

            md5_user_extended_details_params = {}

            data_to_repopulate = {
                birthdate: user_extended_detail.birthdate,
                street_address: user_extended_detail.street_address,
                city: user_extended_detail.city,
                state: user_extended_detail.state,
                country: user_extended_detail.country,
                postal_code: user_extended_detail.postal_code,
                ethereum_address: user_extended_detail.ethereum_address,
                estimated_participation_amount: user_extended_detail.estimated_participation_amount,
                document_id_number: user_extended_detail.document_id_number,
                nationality: user_extended_detail.nationality
            }

            data_to_repopulate.each do |key, value|
              r = decryptor_obj.decrypt(value)
              return r unless r.success?

              md5_user_extended_details_params[key.to_sym] = Md5UserExtendedDetail.get_hashed_value(r.data[:plaintext])
            end

            response = Md5UserExtendedDetail.where(user_extended_detail_id: user_extended_detail.id).update_all(md5_user_extended_details_params)

            if response == 1
              @result[:success] << user_extended_detail.id
            else
              @result[:failure] << user_extended_detail.id
            end

          rescue => e
            @result[:failure] << user_extended_detail.id
          end

        end
      end

      puts "result-----#{@result.inspect}"
    end

    # Decrypt kyc salt
    #
    # * Author: Aman
    # * Date: 30/10/2017
    # * Reviewed By: Abhay
    #
    def decrypt_kyc_salt(kyc_salt_e)
      r = Aws::Kms.new(@run_purpose, @run_role).decrypt(kyc_salt_e)
      fail "decryption of kyc salt failed. for salt- #{kyc_salt_e}" unless r.success?
      r.data[:plaintext]
    end


    @user_ids = ENV['user_ids'].present? ? ENV['user_ids'].split(',').map(&:to_i) : []
    initialize
    perform

  end

end