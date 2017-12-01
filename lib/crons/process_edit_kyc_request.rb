module Crons

  class ProcessEditKycRequest

    include Util::ResultHelper

    # Initialize
    #
    # * Author: Alpesh, kushal
    # * Date: 20/11/2017
    # * Reviewed By:
    #
    # @return [Result::Base]
    #
    def initialize(params)
      @edit_kyc_ars = []
      @case_ids = []
      @user_kyc_details = {}
      @user_extended_details = {}
      @admins = {}
      @users = {}
    end

    # Perform
    #
    # * Author: Alpesh, kushal
    # * Date: 20/11/2017
    # * Reviewed By:
    #
    # @return [Result::Base]
    #
    def perform

      fetch_kycs_to_edit

      edit_kycs

      success

    end

    private

    # Fetch Kycs to be edited
    #
    # * Author: Alpesh, kushal
    # * Date: 20/11/2017
    # * Reviewed By:
    #
    # @return [Result::Base]
    #
    def fetch_kycs_to_edit
      admin_ids = []
      user_ids = []
      user_extended_detail_ids = []

      @edit_kyc_ars = EditKycRequests.unprocessed.limit(1)

      @edit_kyc_ars.each do |e_k_r|
        EditKycRequests.where(id: e_k_r.id).update_all(status: GlobalConstant::UserKycDetail.in_process_edit_kyc)

        @case_ids << e_k_r.case_id
        admin_ids << e_k_r.admin_id
        user_ids << e_k_r.user_id
      end

      UserKycDetail.where(id: @case_ids).each do |u_k_d|
        user_extended_detail_ids << u_k_d.user_extended_detail_id
        @user_kyc_details[u_k_d.id] = u_k_d
      end

      @admins = Admin.where(id: admin_ids).index_by(&:id)
      @users = User.where(id: user_ids).index_by(&:id)
      @user_extended_details = UserExtendedDetail.where(id: user_extended_detail_ids).select("id, kyc_salt").index_by(&:id)
    end

    # Process KYCs and edit/open
    #
    # * Author: Alpesh, kushal
    # * Date: 20/11/2017
    # * Reviewed By:
    #
    # @return [Result::Base]
    #
    def edit_kycs
      @edit_kyc_ars.each do |e_k_r|

        begin

          puts "Editing for the case => #{e_k_r.case_id}--"

          user_extended_detail = @user_extended_details[@user_kyc_details[e_k_r.case_id].user_extended_detail_id]
          ethereum_address = nil

          if e_k_r.ethereum_address.present?
            ethereum_address = decrypt_ethereum_address(e_k_r.ethereum_address, user_extended_detail.kyc_salt)
            fail "ethereum_address could not be decrypted." if ethereum_address.nil?
          end

          user_kyc_details = @user_kyc_details[e_k_r.case_id]

          r = success

          if user_kyc_details.case_closed?

            r = UserAction::OpenCaseAndUpdateEthereumAddress.new(
                case_id: e_k_r.case_id,
                ethereum_address: ethereum_address,
                admin_email: @admins[e_k_r.admin_id].email,
                user_email: @users[e_k_r.user_id].email,
                open_case_only: e_k_r.open_case_only.to_i
            ).perform

          elsif ethereum_address.present?

            r = UserAction::UpdateEthereumAddress.new(
                case_id: e_k_r.case_id,
                ethereum_address: ethereum_address,
                admin_email: @admins[e_k_r.admin_id].email,
                user_email: @users[e_k_r.user_id].email
            ).perform

          end

          if r.success?
            e_k_r.status = GlobalConstant::UserKycDetail.processed_edit_kyc
            email_subject = "Successfully updated case for email: #{@users[e_k_r.user_id].email}"
            email_body = "Success"
            email_to = [@admins[e_k_r.admin_id].email]
          else
            e_k_r.status = GlobalConstant::UserKycDetail.failed_edit_kyc
            e_k_r.debug_data = r.to_json
            email_subject = "Error in updating case for email: #{@users[e_k_r.user_id].email}"
            email_body = r.to_json
            email_to = (GlobalConstant::Email.default_to+[@admins[e_k_r.admin_id].email])
          end

        rescue Exception => e

          e_k_r.status = GlobalConstant::UserKycDetail.failed_edit_kyc
          e_k_r.debug_data = "#{e.message} -- #{e.backtrace}"
          email_subject = "Error in updating case for email: #{@users[e_k_r.user_id].email}"
          email_body = {exception: {message: e.message, backtrace: e.backtrace}}
          email_to = (GlobalConstant::Email.default_to+[@admins[e_k_r.admin_id].email])

        end

        e_k_r.save!

        ApplicationMailer.notify(
            to: email_to,
            body: email_body,
            data: {case_id: e_k_r.case_id, edit_kyc_table_id: e_k_r.id},
            subject: email_subject
        ).deliver

      end
    end

    # encrypt ethereum address.
    #
    # * Author: Alpesh, kushal
    # * Date: 20/11/2017
    # * Reviewed By:
    #
    # @return [Result::Base]
    #
    def decrypt_ethereum_address(encrypted_ethereum_address, kyc_salt)

      r = Aws::Kms.new('kyc', 'admin').decrypt(kyc_salt)
      return r unless r.success?

      kyc_salt_d = r.data[:plaintext]

      encryptor_obj = LocalCipher.new(kyc_salt_d)
      r = encryptor_obj.decrypt(encrypted_ethereum_address)
      return nil unless r.success?

      r.data[:plaintext]
    end

  end

end
