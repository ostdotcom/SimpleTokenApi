module Ocr
  class GetOrientation

    # Initialize
    #
    # @param [Array] words_array(mandatory)
    #
    # * Author: Aniket
    #* Date: 06/06/2018
    #* Reviewed By:
    #
    # Sets @words_array
    #
    def initialize(params)
      @words_array = params[:words_array]

    end

    # Perform
    # * Author: Aniket
    #* Date: 06/06/2018
    #* Reviewed By:
    #
    def perform
      get_orientation
    end


    def get_orientation

      orientation_data = {
          'UNDEFINED' => 0,
          GlobalConstant::ImageProcessing.rotation_angle_0 => 0,
          GlobalConstant::ImageProcessing.rotation_angle_90 => 0,
          GlobalConstant::ImageProcessing.rotation_angle_270 => 0,
          GlobalConstant::ImageProcessing.rotation_angle_180 => 0
      }

      (0..(@words_array.length - 1)).each do |index|

        x_diff = 0
        y_diff = 0
        orientation = nil

        word = @words_array[index]

        next if word.nil? || word.text.size < 3

        x1 = @words_array[index].bounds[0].x
        y1 = @words_array[index].bounds[0].y

        x2 = @words_array[index].bounds[1].x
        y2 = @words_array[index].bounds[1].y

        x_diff = (x2 - x1)
        y_diff = (y2 - y1)

        # x is greater and positive : normal orientation
        # x is greater and negative : inverted orientation
        # y is greater and positive : left orientation
        # y is greater and negative : right orientation

        if x_diff.abs == y_diff.abs
          orientation = 'UNDEFINED'
        end

        if x_diff.abs > y_diff.abs
          if x_diff < 0
            orientation = GlobalConstant::ImageProcessing.rotation_angle_180
          else
            orientation = GlobalConstant::ImageProcessing.rotation_angle_0
          end
        else
          if y_diff < 0
            orientation = GlobalConstant::ImageProcessing.rotation_angle_90
          else
            orientation = GlobalConstant::ImageProcessing.rotation_angle_270
          end
        end

        orientation_data[orientation] += 1
      end

      max_orientation = nil
      max_count = 0

      orientation_data.each do |orientation, count|
        if count > max_count
          max_orientation = orientation
          max_count = count
        end
      end

      return max_orientation
    end

  end
end
