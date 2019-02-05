module GlobalConstant

  class AmlSearch

    class << self

      ### Status start ###

      def unprocessed_status
        'unprocessed'
      end

      def processed_status
        'processed'
      end

      def failed_status
        'failed'
      end

      def deleted_status
        'deleted'
      end

      ### Status End ###

      ### Steps Done start ###

      def search_step_done
        'search'
      end

      def pdf_step_done
        'pdf'
      end

      ### Steps Done End ###

      ### Aml Processing Status start ###

      def unprocessed_aml_processing_status
        'unprocessed'
      end

      def processing_aml_processing_status
        'processing'
      end

      def processed_aml_processing_status
        'processed'
      end


      ### Aml Processing Status End ###

    end

  end

end