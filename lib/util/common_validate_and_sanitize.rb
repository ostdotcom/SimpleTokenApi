module Util

  class CommonValidateAndSanitize

    # for integer array
    #
    # * Author: Kedar
    # * Date: 09/10/2017
    # * Reviewed By: Sunil Khedar
    #
    # @return [Boolean] returns a boolean
    # modifies objects too
    #
    def self.integer_array!(objects)
      return false unless objects.is_a?(Array)

      objects.each_with_index do |o, i|
        return false unless CommonValidator.is_numeric?(o)

        objects[i] = o.to_i
      end

      return true
    end

  end

end
