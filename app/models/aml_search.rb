class AmlSearch < EstablishOstKycAmlDbConnection
  enum status: {
      GlobalConstant::AmlSearch.unprocessed_status => 1,
      GlobalConstant::AmlSearch.processed_status => 2,
      GlobalConstant::AmlSearch.failed_status => 3,
      GlobalConstant::AmlSearch.deleted_status => 4
  }

  enum steps_done: {
      GlobalConstant::AmlSearch.no_step_done => 1,
      GlobalConstant::AmlSearch.search_step_done => 2,
      GlobalConstant::AmlSearch.pdf_step_done => 3
  }
end
