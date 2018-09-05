module FileProcessing

  class PdfToImage
    require 'rmagick'
    include Magick

    include ::Util::ResultHelper

    # Initialize
    #
    # * Author: Pankaj
    # * Date: 12/07/2018
    # * Reviewed By:
    #
    # @param [String] file_directory - File directory to store new file
    # @param [String] file_name - Original PDF file name
    #
    # @return [FileProcessing::PdfToImage]
    #
    def initialize(file_directory, file_name)
      @directory = file_directory
      @file_name = file_name
    end

    # Perform Image creation operation from a Pdf file
    #
    # * Author: Pankaj
    # * Date: 12/07/2018
    # * Reviewed By:
    #
    # @return [String] image_path - Image path, created from pdf
    #
    def perform
      begin
        original_file_name = File.basename(@file_name).gsub(File.extname(@file_name), "")

        new_file_name = "#{@directory}/#{original_file_name}.jpg"

        original_pdf = File.open(@file_name, 'rb').read
        image = Magick::Image::from_blob(original_pdf) do
          self.format = 'PDF'
          self.quality = 100
          self.density = 300
        end
        image_obj = image[0]
        image_obj.format = 'JPG'
        image_obj.background_color = "white"
        image_obj.alpha Magick::RemoveAlphaChannel
        image_obj.to_blob
        image_obj.write(new_file_name)

        return success_with_data(image_path: new_file_name,
                                 width: image_obj.columns, height: image_obj.rows)
      rescue => e
        return exception_with_data(e, "swr", "Something went wrong", "Something went wrong", "", "", e.message)
      end
    end


  end

end