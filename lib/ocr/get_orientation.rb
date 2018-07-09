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
    # * Date: 06/06/2018
    # * Reviewed By:
    #
    # @returns [String] Orientation of the document.
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


      @words_array.each do |word|
        next if word.nil? || word.text.size < 3

        x_diff, y_diff = 0, 0
        orientation = nil

        x1 = word.bounds[0].x
        y1 = word.bounds[0].y

        x2 = word.bounds[1].x
        y2 = word.bounds[1].y

        x_diff = (x2 - x1)
        y_diff = (y2 - y1)

        # x diff is greater than y diff and positive : normal orientation
        # x diff is greater than y diff and negative : inverted orientation
        # y diff is greater than x diff positive : left orientation
        # y diff is greater than x diff and negative : right orientation

        if x_diff.abs == y_diff.abs
          orientation = 'UNDEFINED'
        elsif x_diff.abs > y_diff.abs
          orientation = x_diff < 0 ? GlobalConstant::ImageProcessing.rotation_angle_180 : GlobalConstant::ImageProcessing.rotation_angle_0
        else
          orientation = y_diff < 0 ? GlobalConstant::ImageProcessing.rotation_angle_90 : GlobalConstant::ImageProcessing.rotation_angle_270
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
