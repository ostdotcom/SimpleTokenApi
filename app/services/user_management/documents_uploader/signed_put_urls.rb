module UserManagement

  module DocumentsUploader

    class SignedPutUrls < Base

      # Initialize
      #
      # * Author: Pankaj
      # * Date: 04/09/2018
      # * Reviewed By:
      #
      # @param [AR] client (mandatory) - client obj
      # @param [Hash] images (mandatory)
      # @param [Hash] pdfs (mandatory) - Either pdfs or images should be atleast present
      #
      # @return [UserManagement::DocumentsUploader::SignedPutUrls]
      #
      def initialize(params)
        super
      end

      # Perform
      #
      # * Author: Pankaj
      # * Date: 04/09/2018
      # * Reviewed By: Sunil
      #
      # @return [Result::Base]
      #
      def perform

        super

      end

      private

      # Get AWS Put Url
      #
      # * Author: Pankaj
      # * Date: 04/09/2018
      # * Reviewed By: Sunil
      #
      # @param [String] content_type
      # @param [String] key
      #
      # @return [Hash]
      #
      def get_url(content_type, key)
        url = Aws::S3Manager.new('kyc', 'user').get_presigned_put_url_for(
            key, GlobalConstant::Aws::Common.kyc_bucket, content_type)

        {url: url}
      end

    end

  end

end
