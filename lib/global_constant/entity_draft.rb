module GlobalConstant

  class EntityDraft

    class << self

      ### Status start ###

      def active_status
        'active'
      end

      def deleted_status
        'deleted'
      end

      def draft_status
        'draft'
      end

      ### Status End ###

    end

  end

end
