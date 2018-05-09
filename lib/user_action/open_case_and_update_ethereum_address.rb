# module UserAction
#
#   class OpenCaseAndUpdateEthereumAddress
#
#     include ::Util::ResultHelper
#
#     # Initialize
#     #
#     # * Author: Abhay
#     # * Date: 11/11/2017
#     # * Reviewed By: Sunil
#     #
#     # @param [Integer] case_id (mandatory)
#     # @param [String] admin_email (mandatory)
#     # @param [String] user_email (mandatory)
#     # @param [String] ethereum_address (mandatory)
#     # @param [Integer] open_case_only (optional) Value: 1/0
#     #
#     # @return [UserManagement::OpenCaseAndUpdateEthereumAddress]
#     #
#     # Sets @case_id, @admin_email, @user_email, @new_ethereum_address, @open_case_only, @kyc_whitelist_log
#     #
#     def initialize(params)
#
#       @case_id = params[:case_id]
#       @admin_email = params[:admin_email]
#       @user_email = params[:user_email]
#       @new_ethereum_address = params[:ethereum_address]
#       @open_case_only = (params[:open_case_only].to_i == 1)
#
#       @kyc_whitelist_log = nil
#
#     end
#
#     # Perform
#     #
#     # * Author: Abhay
#     # * Date: 11/11/2017
#     # * Reviewed By: Sunil
#     #
#     # @return [Result::Base]
#     #
#     def perform
#
#       r = validate_and_sanitize
#       return r unless r.success?
#
#       # If case is denied in contract phase will already be 0
#       # No need to set phase=0 again
#       if @client.is_whitelist_setup_done? && @user_kyc_detail.kyc_approved?
#         r = un_whitelist_user
#         return r unless r.success?
#
#         # Because Ethereum Address will also be updated
#         # Let 0 whitelisting kyc_whitelist_log status changed to confirmed status before updating ethereum address
#         sleep_in_secs = 420
#         p "Wait! Sleeping for #{sleep_in_secs} seconds"
#         sleep(sleep_in_secs)
#
#         r = verify_if_un_whitelisted
#         return r unless r.success?
#       end
#
#       r = open_case
#       return r unless r.success?
#
#       r = log_activity
#       return r unless r.success?
#
#       return success if @open_case_only
#
#       update_ethereum_address
#     end
#
#     # Validate and Sanitize
#     #
#     # * Author: Abhay
#     # * Date: 11/11/2017
#     # * Reviewed By: Sunil
#     #
#     # @return [Result::Base]
#     #
#     # Sets @user_kyc_detail, @admin, @user_extended_detail, @client_id, @client
#     #
#     def validate_and_sanitize
#
#       @case_id = @case_id.to_i
#       @admin_email = @admin_email.to_s.downcase.strip
#       @user_email = @user_email.to_s.downcase.strip
#
#       if @case_id < 1 || @admin_email.blank? || @user_email.blank?
#         return error_with_data(
#             'ua_oc_1',
#             'Case ID, Admin Email, User Email is mandatory!',
#             'Case ID, Admin Email, User Email is mandatory!',
#             GlobalConstant::ErrorAction.default,
#             {}
#         )
#       end
#
#       @admin = Admin.where(email: @admin_email, status: GlobalConstant::Admin.active_status).first
#       if @admin.blank?
#         return error_with_data(
#             'ua_oc_2',
#             "Invalid Active Admin Email - #{@admin_email}",
#             "Invalid Active Admin Email - #{@admin_email}",
#             GlobalConstant::ErrorAction.default,
#             {}
#         )
#       end
#
#       @user_kyc_detail = UserKycDetail.where(id: @case_id).first
#       if @user_kyc_detail.blank?
#         return error_with_data(
#             'ua_oc_3',
#             'Invalid Case ID!',
#             'Invalid Case ID!',
#             GlobalConstant::ErrorAction.default,
#             {}
#         )
#       end
#
#       @client_id = @user_kyc_detail.client_id
#       @client = Client.get_from_memcache(@client_id)
#
#
#       if !User.where(id: @user_kyc_detail.user_id, email: @user_email,
#                      status: GlobalConstant::User.active_status).exists?
#         return error_with_data(
#             'ua_oc_4',
#             "User Email: #{@user_email} is Invalid or Not Active!",
#             "User Email: #{@user_email} is Invalid or Not Active!",
#             GlobalConstant::ErrorAction.default,
#             {}
#         )
#       end
#
#       if !@user_kyc_detail.case_closed_for_admin?
#         return error_with_data(
#             'ua_oc_5',
#             "Case ID - #{@case_id} should be closed.",
#             "Case ID - #{@case_id} should be closed.",
#             GlobalConstant::ErrorAction.default,
#             {}
#         )
#       end
#
#       @user_extended_detail = UserExtendedDetail.where(id: @user_kyc_detail.user_extended_detail_id).first
#       if @user_extended_detail.blank?
#         return error_with_data(
#             'ua_oc_7',
#             'Invalid User Extended Details!',
#             'Invalid User Extended Details!',
#             GlobalConstant::ErrorAction.default,
#             {}
#         )
#       end
#
#       r = decrypt_ethereum_address
#       return r unless r.success?
#
#       r = validate_for_whitelisting
#       return r unless r.success?
#
#       r = validate_for_st_token_sale_default_client
#       return r unless r.success?
#
#       success
#     end
#
#     # Validate for whitelisting
#     #
#     # * Author: Aman
#     # * Date: 27/12/2017
#     # * Reviewed By:
#     #
#     # @return [Result::Base]
#     #
#     def validate_for_whitelisting
#       return success unless @client.is_whitelist_setup_done?
#
#       if @user_kyc_detail.kyc_approved? && [GlobalConstant::UserKycDetail.unprocessed_whitelist_status,
#                                             GlobalConstant::UserKycDetail.started_whitelist_status].include?(@user_kyc_detail.whitelist_status)
#
#         return error_with_data(
#             'ua_oc_6',
#             "Whitelist is in progress. Let it be completed to done!",
#             "Whitelist is in progress. Let it be completed to done!",
#             GlobalConstant::ErrorAction.default,
#             {}
#         )
#       end
#
#       KycWhitelistLog.where(client_id: @client_id, ethereum_address: @ethereum_address).all.each do |kwl|
#
#         if (kwl.status != GlobalConstant::KycWhitelistLog.confirmed_status)
#           return error_with_data(
#               'ua_oc_9',
#               "Existing Kyc White Log ID: #{kwl.id} is not in confirmed status. Also check is_attention_needed value.",
#               "Existing Kyc White Log ID: #{kwl.id} is not in confirmed status. Also check is_attention_needed value.",
#               GlobalConstant::ErrorAction.default,
#               {}
#           )
#         end
#
#         if kwl.updated_at >= (Time.now - 10.minutes)
#           return error_with_data(
#               'ua_oc_10',
#               "Existing Kyc White Log ID: #{kwl.id} is just confirmed under 10 minutes. Please try after 10 minutes.",
#               "Existing Kyc White Log ID: #{kwl.id} is just confirmed under 10 minutes. Please try after 10 minutes.",
#               GlobalConstant::ErrorAction.default,
#               {}
#           )
#         end
#
#       end
#
#       success
#     end
#
#     # Validations for default st token sale client
#     #
#     # * Author: Aman
#     # * Date: 27/12/2017
#     # * Reviewed By:
#     #
#     # @return [Result::Base]
#     #
#     def validate_for_st_token_sale_default_client
#       return success unless @client.is_st_token_sale_client?
#
#       if PurchaseLog.of_ethereum_address(@ethereum_address).exists?
#         return error_with_data(
#             'ua_oc_8',
#             "User already bought SimpleToken. His case can't be opened",
#             "User already bought SimpleToken. His case can't be opened",
#             GlobalConstant::ErrorAction.default,
#             {}
#         )
#       end
#
#       success
#     end
#
#     # Decrypt Ethereum Address
#     #
#     # * Author: Abhay
#     # * Date: 11/11/2017
#     # * Reviewed By: Sunil
#     #
#     # @return [Result::Base]
#     #
#     # Sets @kyc_salt_d, @ethereum_address
#     #
#     def decrypt_ethereum_address
#
#       r = Aws::Kms.new('kyc', 'admin').decrypt(@user_extended_detail.kyc_salt)
#
#       unless r.success?
#         return error_with_data(
#             'ua_oc_11',
#             'Error decrypting Kyc salt!',
#             'Error decrypting Kyc salt!',
#             GlobalConstant::ErrorAction.default,
#             {}
#         )
#       end
#
#       @kyc_salt_d = r.data[:plaintext]
#
#       r = local_cipher_obj.decrypt(@user_extended_detail.ethereum_address)
#       return r unless r.success?
#
#       @ethereum_address = r.data[:plaintext]
#
#       p "######  OLD ETHEREUM ADDRESS: #{@ethereum_address}  ######"
#
#       success
#     end
#
#     # Make Whitelist API call
#     #
#     # * Author: Abhay
#     # * Date: 11/11/2017
#     # * Reviewed By: Sunil
#     #
#     # @return [Result::Base]
#     #
#     # Sets @kyc_whitelist_log
#     #
#     def un_whitelist_user
#       Rails.logger.info("user_kyc_detail id:: #{@user_kyc_detail.id} - making private ops api call")
#       r = OpsApi::Request::Whitelist.new.whitelist({
#                                                        whitelister_address: api_data[:client_whitelist_detail_obj].whitelister_address,
#                                                        contract_address: api_data[:client_whitelist_detail_obj].contract_address,
#                                                        address: api_data[:address],
#                                                        phase: api_data[:phase]
#                                                    })
#       Rails.logger.info("Whitelist API Response: #{r.inspect}")
#       return r unless r.success?
#
#       @kyc_whitelist_log = KycWhitelistLog.create!({
#                                                        client_id: @client_id,
#                                                        ethereum_address: api_data[:address],
#                                                        phase: api_data[:phase],
#                                                        transaction_hash: r.data[:transaction_hash],
#                                                        status: GlobalConstant::KycWhitelistLog.pending_status,
#                                                        is_attention_needed: 0
#                                                    })
#       success
#     end
#
#     # Open Case DB Changes
#     #
#     # * Author: Abhay
#     # * Date: 11/11/2017
#     # * Reviewed By: Sunil
#     #
#     def open_case
#
#       @user_kyc_detail.admin_status = GlobalConstant::UserKycDetail.unprocessed_admin_status
#       @user_kyc_detail.whitelist_status = GlobalConstant::UserKycDetail.unprocessed_whitelist_status
#       @user_kyc_detail.record_timestamps = false
#       @user_kyc_detail.save!
#
#       success
#     end
#
#     # API Data for phase 0
#     #
#     # * Author: Abhay
#     # * Date: 11/11/2017
#     # * Reviewed By: Sunil
#     #
#     # @return [Hash]
#     #
#     def api_data
#       @api_data ||= {
#           address: @ethereum_address,
#           phase: 0,
#           client_whitelist_detail_obj: get_client_whitelist_detail_obj
#       }
#     end
#
#     # Get client_whitelist_detail obj
#     #
#     # * Author: Aman
#     # * Date: 29/12/2017
#     # * Reviewed By:
#     #
#     # @return [Ar] ClientWhitelistDetail obj
#     #
#     def get_client_whitelist_detail_obj
#       ClientWhitelistDetail.where(client_id: @user_kyc_detail.client_id,
#                                   status: GlobalConstant::ClientWhitelistDetail.active_status).first
#     end
#
#     # Construct local cipher object
#     #
#     # * Author: Abhay
#     # * Date: 11/11/2017
#     # * Reviewed By: Sunil
#     #
#     # @return [LocalCipher]
#     #
#     # Sets @local_cipher_obj
#     #
#     def local_cipher_obj
#       @local_cipher_obj ||= LocalCipher.new(@kyc_salt_d)
#     end
#
#     # Log to UserActivityLog Table
#     #
#     # * Author: Abhay
#     # * Date: 11/11/2017
#     # * Reviewed By: Sunil
#     #
#     # @return [Result::Base]
#     #
#     def log_activity
#
#       BgJob.enqueue(
#           UserActivityLogJob,
#           {
#               user_id: @user_kyc_detail.user_id,
#               admin_id: @admin.id,
#               action: GlobalConstant::UserActivityLog.open_case,
#               action_timestamp: Time.now.to_i,
#               extra_data: {
#                   case_id: @case_id,
#                   user_extended_detail_id: @user_extended_detail.id
#               }
#           }
#       )
#
#       success
#     end
#
#     # Check if user is un_whitelisted
#     #
#     # * Author: Abhay
#     # * Date: 11/11/2017
#     # * Reviewed By: Sunil
#     #
#     # @return [Result::Base]
#     #
#     def verify_if_un_whitelisted
#
#       kwl = KycWhitelistLog.where(id: @kyc_whitelist_log.id, status: GlobalConstant::KycWhitelistLog.confirmed_status,
#                                   is_attention_needed: GlobalConstant::KycWhitelistLog.attention_not_needed).first
#       if kwl.blank?
#         return error_with_data(
#             'ua_oc_12',
#             "KycWhitelistLog: #{@kyc_whitelist_log.id} is still not confirmed or it's marked is_attention_needed!",
#             "KycWhitelistLog: #{@kyc_whitelist_log.id} is still not confirmed or it's marked is_attention_needed!",
#             GlobalConstant::ErrorAction.default,
#             {}
#         )
#       end
#
#       r = OpsApi::Request::GetWhitelistStatus.new.perform(contract_address: api_data[:client_whitelist_detail_obj].contract_address, ethereum_address: @ethereum_address)
#       return r unless r.success?
#
#       _phase = r.data['phase']
#
#       if !Util::CommonValidator.is_numeric?(_phase) || r.data['phase'].to_i != 0
#         return error_with_data(
#             'ua_oc_13',
#             "Invalid Phase: #{_phase} for KycWhitelistLog: #{kwl.id}",
#             "Invalid Phase: #{_phase} for KycWhitelistLog: #{kwl.id}",
#             GlobalConstant::ErrorAction.default,
#             {}
#         )
#       end
#
#       if @client.is_st_token_sale_client? && PurchaseLog.of_ethereum_address(@ethereum_address).exists?
#         return error_with_data(
#             'ua_oc_14',
#             "User already bought SimpleToken. His case can't be opened",
#             "User already bought SimpleToken. His case can't be opened",
#             GlobalConstant::ErrorAction.default,
#             {}
#         )
#       end
#
#       success
#     end
#
#     # Update Ethereum Address
#     #
#     # * Author: Abhay
#     # * Date: 11/11/2017
#     # * Reviewed By: Sunil
#     #
#     # @return [Result::Base]
#     #
#     def update_ethereum_address
#       UserAction::UpdateEthereumAddress.new(
#           case_id: @case_id,
#           ethereum_address: @new_ethereum_address,
#           admin_email: @admin_email,
#           user_email: @user_email
#       ).perform
#     end
#
#   end
#
# end