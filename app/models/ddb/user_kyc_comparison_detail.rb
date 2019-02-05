module Ddb
  # todo: use base
  class UserKycComparisonDetail

    include Ddb::Table

    table :raw_name => 'user_kyc_comparison_details',
          :partition_key => GlobalConstant::Aws::Ddb::UserKycComparisonDetail.partition_key,
          :sort_key => GlobalConstant::Aws::Ddb::UserKycComparisonDetail.sort_key,
          :indexes => GlobalConstant::Aws::Ddb::UserKycComparisonDetail.indexes,
          :merged_columns => GlobalConstant::Aws::Ddb::UserKycComparisonDetail.merged_columns,
          :delimiter => "#"


    # todo: enum handle mapping
    def self.image_processing_status_enum
      {
          0 => GlobalConstant::ImageProcessing.unprocessed_image_process_status,
          1 => GlobalConstant::ImageProcessing.processed_image_process_status,
          2 => GlobalConstant::ImageProcessing.failed_image_process_status
      }
    end


    def initialize(params, options = {})
      @shard_id = params[:shard_id]
      @use_column_mapping = options[:use_column_mapping]

      set_table_name
    end

    def self.auto_approve_failed_reasons_config
      @auto_approve_failed_reasons_config ||= {
          GlobalConstant::KycAutoApproveFailedReason.unexpected_reason => 1,
          GlobalConstant::KycAutoApproveFailedReason.document_file_invalid => 2,
          GlobalConstant::KycAutoApproveFailedReason.selfie_file_invalid => 4,
          GlobalConstant::KycAutoApproveFailedReason.ocr_unmatch => 8,
          GlobalConstant::KycAutoApproveFailedReason.fr_unmatch => 16,
          GlobalConstant::KycAutoApproveFailedReason.residency_proof => 32,
          GlobalConstant::KycAutoApproveFailedReason.investor_proof => 64,
          GlobalConstant::KycAutoApproveFailedReason.duplicate_kyc => 128,
          GlobalConstant::KycAutoApproveFailedReason.token_sale_ended => 256,
          GlobalConstant::KycAutoApproveFailedReason.case_closed_for_auto_approve => 512,
          GlobalConstant::KycAutoApproveFailedReason.human_labels_percentage_low => 1024
      }
    end

    def auto_approve_failed_reasons_array
      @auto_approve_failed_reasons_array = UserKycComparisonDetail.get_bits_set_for_auto_approve_failed_reasons(auto_approve_failed_reasons)
    end

    # Bitwise columns config

    def self.bit_wise_columns_config
      @b_w_c_c ||= {
          auto_approve_failed_reasons: auto_approve_failed_reasons_config
      }
    end

    # test all valid functions with ddb object
    include BitWiseConcern

    # todo: move to base
    def initialize_instance_variables(hash)
      hash.each do |k, v|
        instance_variable_set("@#{k}", v)
        self.class.send(:attr_accessor, k)
      end if hash.present?
      self
    end

    def set_table_name
      table_info[:name] = "#{Rails.env}_#{@shard_id}_#{self.class.raw_table_name}"
    end

    def use_column_mapping?
      @use_column_mapping == false ? false : true
    end

  end
end


