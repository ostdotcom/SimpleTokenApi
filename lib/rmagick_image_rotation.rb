class RmagickImageRotation

  require 'rmagick'
  include Magick

  include ::Util::ResultHelper

  # Initialize
  #
  # * Author: Pankaj
  # * Date: 20/06/2018
  # * Reviewed By:
  #
  # @param [String] image_path - Original Image path
  # @param [Integer] rotation_angle - Rotation Angle to rotate image with
  #
  # @return [RmagickImageRotation]
  #
  def initialize(image_path, rotation_angle)
    @image_file = image_path
    @angle = rotation_angle
  end

  # Perform Rotation operation on the image
  #
  # * Author: Pankaj
  # * Date: 20/06/2018
  # * Reviewed By:
  #
  # @return [String] rotated_image_path - Image path after rotation
  #
  def perform
    begin
      file = File.open(@image_file)

      original_file_name = File.basename(@image_file).gsub(File.extname(@image_file), "")

      new_file_name = "#{Rails.root}/public/#{original_file_name}-#{@angle}.jpg"

      image_obj = ImageList.new(@image_file)

      image_obj.rotate!(@angle)

      image_obj.strip!

      # image_obj.format = "PNG"

      image_obj.write(new_file_name)

      return success_with_data(rotated_image_path: new_file_name)
    rescue => e
      return exception_with_data(e, "swr", "Something went wrong", "Something went wrong", "", "", e.message)
    end
  end

end