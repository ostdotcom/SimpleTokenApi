class AmlLog

  module Methods
    extend ActiveSupport::Concern
    included do

      enum request_type: {
          GlobalConstant::AmlLog.person_search_request_type => 1,
          GlobalConstant::AmlLog.person_get_profile_pdf_request_type => 2
      }

    end

    module ClassMethods

    end
  end


end
