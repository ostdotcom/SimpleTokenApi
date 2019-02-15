module Util
  class CustomErrorFormatter
    class << self

    # Format deep error hash in single level hash
    #
    # * Author: Aniket
    # * Date: 28/08/2018
    # * Reviewed By:
    #
    def format_error_for_update_config(error_data)
      formatted_errors = {}
      error_data.each do |key, val|
        formatted_errors.merge!(get_error(val, key))
      end
      formatted_errors
    end

    private

    # Format deep error hash in single level hash recursively
    #
    # * Author: Aniket
    # * Date: 28/08/2018
    # * Reviewed By:
    #
    def get_error(error, prefix)
      err = {}
      if error.is_a? String
        # if the passed_param is a string, sanitize it directly to remove script tags etc
        err["#{prefix}"] = error
      elsif error.is_a?(Hash)
        # if the passed_param is a hash, sanitize the values.
        # we are not sanitizing keys, as not known keys will not be accessed - assumption
        error.each do |err_key, err_val|
          err.merge!(get_error(err_val, "#{prefix}[#{err_key}]"))
        end
      elsif error.is_a? Array
        # if passed_param is a array, sanitize each element
        error.each_with_index do |err_val, index|
          err.merge!(get_error(err_val, "#{prefix}[#{index}]"))
        end
      end
      err
    end

    end

  end

end
