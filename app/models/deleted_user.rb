class DeletedUser

  module Methods
    extend ActiveSupport::Concern

    included do

      enum status: {
          GlobalConstant::DeletedUser.active_status => 1,
          GlobalConstant::DeletedUser.reactived_status => 2
      }

    end

    module ClassMethods

    end

  end

end
