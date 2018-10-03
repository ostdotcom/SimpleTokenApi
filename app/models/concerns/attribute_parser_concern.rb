module AttributeParserConcern

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
      binding.pry
      self.singleton_class.bit_wise_columns_config.present? && self.singleton_class.bit_wise_columns_config.each do |col, _|
        hashed_data["#{col}_array"] = self.singleton_class.send("get_bits_set_for_#{col}", self.send(col))
      end

      self.singleton_class.restricted_fields.each do |col|
        hashed_data.delete(col.to_s)
      end

      if self.extra_fields_to_set.present?
        hashed_data.merge!(self.extra_fields_to_set)
      end

      hashed_data.symbolize_keys
    end

    # Columns to be removed from the hashed response
    #
    # * Author: Aman
    # * Date: 28/09/2018
    # * Reviewed By:
    #
    def self.restricted_fields
      []
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

  end

end