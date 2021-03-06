module AttributeParserConcern

  # should be initialized after bitwise concern

  extend ActiveSupport::Concern
  included do

    # Gives the hashed attributes of the model object
    #
    # * Author: Aman
    # * Date: 28/09/2018
    # * Reviewed By:
    #
    # returns [Hash] attributes converted to Hash with filtered fields
    #
    def get_hash
      hashed_data = self.attributes
      self.singleton_class.try(:bit_wise_columns_config).present? && self.singleton_class.bit_wise_columns_config.each do |col, _|
        hashed_data["#{col}_array"] = self.singleton_class.send("get_bits_set_for_#{col}", self.send(col))
      end

      self.singleton_class.restricted_fields.each do |col|
        hashed_data.delete(col.to_s)
      end

      if extra_fields_to_set.present?
        hashed_data.merge!(extra_fields_to_set)
      end

      hashed_data.each do |k, v|
        hashed_data[k] = v.to_i if v.present? && v.methods.include?(:strftime)
      end

      hashed_data.symbolize_keys
    end

    # Set the extra needed data for hashed response
    #
    # * Author: Aman
    # * Date: 28/09/2018
    # * Reviewed By:
    #
    def extra_fields_to_set
      {}
    end

  end


  class_methods do

    # Columns to be removed from the hashed response
    #
    # * Author: Aman
    # * Date: 28/09/2018
    # * Reviewed By:
    #
    def restricted_fields
      []
    end

  end

end