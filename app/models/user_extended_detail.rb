class UserExtendedDetail < EstablishSimpleTokenUserDbConnection

  # Check if Duplicate KYC Approved User
  #
  # * Author: Abhay
  # * Date: 30/10/2017
  # * Reviewed By: Sunil
  #
  # return [Bool] true/false
  #
  def self.is_duplicate_kyc_approved_user?(client_id, user_extended_detail_id)
    u_e_d = UserExtendedDetail.where(id: user_extended_detail_id).first

    hashed_nationality = Util::Encryption::Admin.get_sha256_hashed_value_from_kms_encrypted_value(u_e_d.kyc_salt, u_e_d.nationality)
    hashed_document_id_number = Util::Encryption::Admin.get_sha256_hashed_value_from_kms_encrypted_value(u_e_d.kyc_salt, u_e_d.document_id_number)

    where_clause = '(document_id_number = ? && nationality = ?)'
    where_clause_values = [hashed_document_id_number, hashed_nationality]

    if u_e_d.ethereum_address.present?
      hashed_ethereurm_address = Util::Encryption::Admin.get_sha256_hashed_value_from_kms_encrypted_value(u_e_d.kyc_salt, u_e_d.ethereum_address)
      where_clause += 'or (ethereum_address = ?)'
      where_clause_values << hashed_ethereurm_address
    end

    user_extended_detail_ids = Md5UserExtendedDetail.
        where(where_clause + where_clause_values).
        pluck(:user_extended_detail_id)

    user_extended_detail_ids.delete(user_extended_detail_id)
    return false if user_extended_detail_ids.blank?
    UserKycDetail.where(client_id: client_id, user_extended_detail_id: user_extended_detail_ids, admin_status: GlobalConstant::UserKycDetail.admin_approved_statuses).exists?
  end
end
