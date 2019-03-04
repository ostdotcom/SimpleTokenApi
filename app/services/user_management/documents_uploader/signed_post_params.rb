module UserManagement

  module DocumentsUploader

    class SignedPostParams < Base

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
      # @return [UserManagement::DocumentsUploader::SignedPostParams]
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

      # Get AWS Post Url
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
        post = Aws::S3Manager.new('kyc', 'user').get_presigned_post_url_for(content_type, key, GlobalConstant::Aws::Common.kyc_bucket)

        {url: post.url, fields: post.fields}
      end

    end

  end

end
