class ClientKycAutoApproveSetting < EstablishSimpleTokenClientDbConnection

  enum status: {
      GlobalConstant::ClientKycAutoApproveSettings.active_status => 1,
      GlobalConstant::ClientKycAutoApproveSettings.inactive_status => 2
  }

  # OCR comparison columns config
  #
  # * Author: Pankaj
  # * Date: 02/07/2018
  # * Reviewed By:
  #
  def self.ocr_comparison_columns_config
    @ocr_col_con ||= {
        GlobalConstant::ClientKycAutoApproveSettings.first_name_ocr_comparison_column => 1,
        GlobalConstant::ClientKycAutoApproveSettings.last_name_ocr_comparison_column => 2,
        GlobalConstant::ClientKycAutoApproveSettings.document_id_ocr_comparison_column => 4,
        GlobalConstant::ClientKycAutoApproveSettings.nationality_ocr_comparison_column => 8,
        GlobalConstant::ClientKycAutoApproveSettings.birthdate_ocr_comparison_column => 16
    }
  end

  # Bitwise columns config
  #
  # * Author: Pankaj
  # * Date: 02/07/2018
  # * Reviewed By:
  #
  def self.bit_wise_columns_config
    @b_w_c_c ||= {
        ocr_comparison_columns: ocr_comparison_columns_config
    }
  end

  # Note : always include this after declaring bit_wise_columns_config method
  include BitWiseConcern
end
