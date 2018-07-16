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
  # @param [String] file_directory - File directory to store new file
  # @param [String] image_path - Original Image path
  # @param [Integer] rotation_angle - Rotation Angle to rotate image with
  #
  # @return [RmagickImageRotation]
  #
  def initialize(file_directory, image_path, rotation_angle)
    @directory = file_directory
    @image_file = image_path
    @rotation_angle = rotation_angle
    @angle = GlobalConstant::ImageProcessing.rotation_angles[@rotation_angle]
  end

  # Perform Rotation operation on the image
  #
  # * Author: Pankaj
  # * Date: 20/06/2018
  # * Reviewed By:
  #
  # @return [Result::Base] rotated_image_path - Image path after rotation
  #
  def perform
    begin
      original_file_name = File.basename(@image_file).gsub(File.extname(@image_file), "")

      new_file_name = "#{@directory}/#{original_file_name}_#{@rotation_angle}.jpg"

      image_obj = ImageList.new(@image_file)

      is_big_image = image_obj.filesize > 10000000 # File size is greater than 10MB

      image_obj.density = "200x200"

      image_obj.rotate!(@angle)

      image_obj.strip!

      if is_big_image # File size is greater than 10MB, reduce quality to 80%
        image_obj.write(new_file_name){self.quality = 80}
      else
        image_obj.write(new_file_name)
      end

      return success_with_data(rotated_image_path: new_file_name, rotation_angle: @rotation_angle,
                               width: image_obj.columns, height: image_obj.rows)
    rescue => e
      return exception_with_data(e, "swr", "Something went wrong", "Something went wrong", "", "", e.message)
    end
  end

end