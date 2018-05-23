# module Crons
#
#   class ProcessEditKycRequest
#
#     include Util::ResultHelper
#
#     # Initialize
#     #
#     # * Author: Alpesh, kushal
#     # * Date: 20/11/2017
#     # * Reviewed By:
#     #
#     # @return [Result::Base]
#     #
#     def initialize(params)
#       @edit_kyc_ars = []
#       @case_ids = []
#       @user_kyc_details = {}
#       @user_extended_details = {}
#       @admins = {}
#       @users = {}
#     end
#
#     # Perform
#     #
#     # * Author: Alpesh, kushal
#     # * Date: 20/11/2017
#     # * Reviewed By:
#     #
#     # @return [Result::Base]
#     #
#     def perform
#
#       fetch_kycs_to_edit
#
#       edit_kycs
#
#       success
#
#     end
#
#     private
#
#     # Fetch Kycs to be edited
#     #
#     # * Author: Alpesh, kushal
#     # * Date: 20/11/2017
#     # * Reviewed By:
#     #
#     # @return [Result::Base]
#     #
#     def fetch_kycs_to_edit
#       admin_ids = []
#       user_ids = []
#       user_extended_detail_ids = []
#
#       @edit_kyc_ars = EditKycRequests.unprocessed.limit(1)
#
#       @edit_kyc_ars.each do |e_k_r|
#         EditKycRequests.where(id: e_k_r.id).update_all(status: GlobalConstant::UserKycDetail.in_process_edit_kyc)
#
#         @case_ids << e_k_r.case_id
#         admin_ids << e_k_r.admin_id
#         user_ids << e_k_r.user_id
#       end
#
#       UserKycDetail.where(id: @case_ids).each do |u_k_d|
#         user_extended_detail_ids << u_k_d.user_extended_detail_id
#         @user_kyc_details[u_k_d.id] = u_k_d
#       end
#
#       @admins = Admin.where(id: admin_ids).index_by(&:id)
#       @users = User.where(id: user_ids).index_by(&:id)
#       @user_extended_details = UserExtendedDetail.where(id: user_extended_detail_ids).select("id, kyc_salt").index_by(&:id)
#     end
#
#     # Process KYCs and edit/open
#     #
#     # * Author: Alpesh, kushal
#     # * Date: 20/11/2017
#     # * Reviewed By:
#     #
#     # @return [Result::Base]
#     #
#     def edit_kycs
#       @edit_kyc_ars.each do |e_k_r|
#         is_success = 0
#         reason_failure_msg = nil
#
#         begin
#
#           puts "Editing for the case => #{e_k_r.case_id}--"
#
#           user_extended_detail = @user_extended_details[@user_kyc_details[e_k_r.case_id].user_extended_detail_id]
#           ethereum_address = nil
#
#           if e_k_r.ethereum_address.present?
#             ethereum_address = decrypt_ethereum_address(e_k_r.ethereum_address, user_extended_detail.kyc_salt)
#             fail "ethereum_address could not be decrypted." if ethereum_address.nil?
#           end
#
#           user_kyc_details = @user_kyc_details[e_k_r.case_id]
#
#           r = success
#
#           if user_kyc_details.case_closed_for_admin?
#             r = UserAction::OpenCaseAndUpdateEthereumAddress.new(
#                 case_id: e_k_r.case_id,
#                 ethereum_address: ethereum_address,
#                 admin_email: @admins[e_k_r.admin_id].email,
#                 user_email: @users[e_k_r.user_id].email,
#                 open_case_only: e_k_r.open_case_only.to_i
#             ).perform
#
#           elsif ethereum_address.present?
#
#             r = UserAction::UpdateEthereumAddress.new(
#                 case_id: e_k_r.case_id,
#                 ethereum_address: ethereum_address,
#                 admin_email: @admins[e_k_r.admin_id].email,
#                 user_email: @users[e_k_r.user_id].email
#             ).perform
#
#           end
#
#           if r.success?
#             e_k_r.status = GlobalConstant::UserKycDetail.processed_edit_kyc
#             is_success = 1
#           else
#             e_k_r.status = GlobalConstant::UserKycDetail.failed_edit_kyc
#             e_k_r.debug_data = r.to_json
#             reason_failure_msg = r.error_message
#           end
#
#         rescue Exception => e
#           e_k_r.status = GlobalConstant::UserKycDetail.failed_edit_kyc
#           e_k_r.debug_data = "#{e.message} -- #{e.backtrace}"
#           reason_failure_msg = "Something went wrong. We are looking into it"
#
#           ApplicationMailer.notify(
#               to: GlobalConstant::Email.default_to,
#               body: e.message,
#               data: {case_id: e_k_r.case_id, edit_kyc_table_id: e_k_r.id, backtrace: e.backtrace},
#               subject: "Exception::Something went wrong while edit kyc request"
#           ).deliver
#         end
#
#         e_k_r.save!
#
#
#         if user_kyc_details.case_closed_for_admin?
#           ethereum_address_updated = e_k_r.open_case_only.to_i > 0 ?  0 : 1
#
#           Email::HookCreator::SendTransactionalMail.new(
#               client_id: Client::OST_KYC_CLIENT_IDENTIFIER,
#               email: @admins[e_k_r.admin_id].email,
#               template_name: GlobalConstant::PepoCampaigns.open_case_request_outcome_template,
#               template_vars: {success: is_success, email: @users[e_k_r.user_id].email, reason_failure: reason_failure_msg, ethereum_address_updated: ethereum_address_updated}
#           ).perform
#         else
#           Email::HookCreator::SendTransactionalMail.new(
#               client_id: Client::OST_KYC_CLIENT_IDENTIFIER,
#               email: @admins[e_k_r.admin_id].email,
#               template_name: GlobalConstant::PepoCampaigns.update_ethereum_request_outcome_template,
#               template_vars: {success: is_success, email: @users[e_k_r.user_id].email, reason_failure: reason_failure_msg}
#           ).perform
#         end
#
#       end
#     end
#
#     # encrypt ethereum address.
#     #
#     # * Author: Alpesh, kushal
#     # * Date: 20/11/2017
#     # * Reviewed By:
#     #
#     # @return [Result::Base]
#     #
#     def decrypt_ethereum_address(encrypted_ethereum_address, kyc_salt)
#
#       r = Aws::Kms.new('kyc', 'admin').decrypt(kyc_salt)
#       return r unless r.success?
#
#       kyc_salt_d = r.data[:plaintext]
#
#       encryptor_obj = LocalCipher.new(kyc_salt_d)
#       r = encryptor_obj.decrypt(encrypted_ethereum_address)
#       return nil unless r.success?
#
#       r.data[:plaintext]
#     end
#
#   end
#
# end
