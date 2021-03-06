module BitWiseConcern

  extend ActiveSupport::Concern
  included do

    def fetch_value_from_ar_object(column_name)
      send(column_name) || 0
    end

    # validate if model has implemented unique values only
    #
    # * Author: Aman
    # * Date: 11/10/2017
    # * Reviewed By: Sunil
    #
    buffer = self.bit_wise_columns_config.inject([]) do |buffer, (_, values_hash)|
      buffer += values_hash.keys
    end
    fail "BIT_WISE_COLUMNS does not contain unique keys #{self.bit_wise_columns_config}" if buffer.uniq!.present?

    # get the values for bits which are currently set
    #
    # * Author: Aman
    # * Date: 11/10/2017
    # * Reviewed By: Sunil
    #
    # @param bit_value [Integer] : bit_value ex : 9
    # @return Array[Integer] : ex : [1,8]
    #
    self.singleton_class.send(:define_method, 'get_set_bits') { |bit_value|
      (0...bit_value.bit_length).map { |n| bit_value[n] << n }.reject(&:zero?)
    }

    self.bit_wise_columns_config.each do |column_name, values_hash|

      # get a hash of all values for a column indexed by integer value
      #
      # * Author: Aman
      # * Date: 11/10/2017
      # * Reviewed By: Sunil
      #
      # @return Hash : ex -> {1=>:bit_1_property, 2=>:bit_2_property, 4=>:bit_3_property, 8=>:bit_4_property}
      #
      self.singleton_class.send(:define_method, "inverted_values_for_#{column_name}") {
        value_from_cache = instance_variable_get("@i_values_for_#{column_name}")
        if value_from_cache.present?
          value_from_cache
        else
          value = send("values_for_#{column_name}").invert
          instance_variable_set("@i_values_for_#{column_name}", value)
        end
      }

      # get a hash of all values for a column indexed by string identifier
      #
      # * Author: Aman
      # * Date: 11/10/2017
      # * Reviewed By: Sunil
      #
      # @return Hash : ex -> {::bit_1_property=>1, :bit_2_property=>2, :bit_3_property=>4, :bit_4_property=>8}
      #
      self.singleton_class.send(:define_method, "values_for_#{column_name}") {
        value_from_cache = instance_variable_get("@values_for_#{column_name}")
        if value_from_cache.present?
          value_from_cache
        else
          instance_variable_set("@values_for_#{column_name}", values_hash)
        end
      }

      # given a integer bit_value get which bits are set and unset for a column name
      #
      # Fixnum#bit_length returns the position of the highest "1" bit
      # Fixnum#[n] returns the integer's nth bit, i.e. 0 or 1
      # Fixnum#<< shifts the bit to the left. 1 << n is equivalent to 2n
      #
      # * Author: Aman
      # * Date: 11/10/2017
      # * Reviewed By: Sunil
      #
      # @param [Integer] : integer bit_value
      # @return [Hash] : has two keys set & unset and has an array against each of them
      # ex : {:set=>[:one, :four], :unset=>[:two, :three]}
      #
      self.singleton_class.send(:define_method, "get_bits_info_for_#{column_name}") { |bit_value|
        set_bits = get_set_bits(bit_value)
        values_map = send("inverted_values_for_#{column_name}")
        set_values = set_bits.map{|value| values_map[value]}
        unset_values = (values_map.keys - set_bits).map{|value| values_map[value]}
        {
            set: set_values,
            unset: unset_values
        }
      }

      # given a integer bit_value get which bits are set and unset for a column name
      #
      # * Author: Aman
      # * Date: 11/10/2017
      # * Reviewed By: Sunil
      #
      # @param [Integer] : integer bit_value
      # @return [Array] : has an array of set values
      # ex : [:one, :four]
      #
      self.singleton_class.send(:define_method, "get_bits_set_for_#{column_name}") { |bit_value|
        set_bits = get_set_bits(bit_value)
        values_map = send("inverted_values_for_#{column_name}")
        set_bits.map{|value| values_map[value]}
      }

      # given a integer bit_value get which bits are set and unset for a column name
      #
      # * Author: Aman
      # * Date: 11/10/2017
      # * Reviewed By: Sunil
      #
      # @param [Array] : array of symobolizied keys representing bits which are to be set ex -> [:one, :four]
      # @return [Integer] : bit_value ex -> 5
      #
      self.singleton_class.send(:define_method, "generate_bit_value_for_#{column_name}") { |keys|
        values_map = send("values_for_#{column_name}")
        keys.inject(0) {|bit_value, key| bit_value |= values_map[key] }
      }

      # returns info for bits which are set & unset
      #
      # * Author: Aman
      # * Date: 11/10/2017
      # * Reviewed By: Sunil
      #
      # @return [Hash] : {:set=>[:bit_1_property, :bit_2_property], :unset=>[:bit_3_property]}
      #
      define_method("get_bits_info_for_#{column_name}") {
        bit_value = fetch_value_from_ar_object(column_name)
        self.class.send("get_bits_info_for_#{column_name}", bit_value)
      }

      # returns values for bits which are currently set
      #
      # * Author: Aman
      # * Date: 11/10/2017
      # * Reviewed By: Sunil
      #
      # @return [Array] : [:bit_1_property, :bit_2_property]
      #
      define_method("get_bits_set_for_#{column_name}") {
        bit_value = fetch_value_from_ar_object(column_name)
        self.class.send("get_bits_set_for_#{column_name}", bit_value)
      }

      # unset all bits of a column name
      #
      # * Author: Aman
      # * Date: 11/10/2017
      # * Reviewed By: Sunil
      #
      define_method("unset_#{column_name}") {
        current_val = fetch_value_from_ar_object(column_name)
        final_val = current_val & 0
        self.send("#{column_name}=", final_val)
      }

      values_hash.each do |attribute, value|

        # find all the rows which have the bit set
        #
        # * Author: Aman
        # * Date: 11/10/2017
        # * Reviewed By: Sunil
        #
        self.singleton_class.send(:define_method, attribute) {
          where("#{column_name} & #{value} > 0")
        }

        # check if this bit is set
        #
        # * Author: Aman
        # * Date: 11/10/2017
        # * Reviewed By: Sunil
        #
        define_method("#{attribute}?") {
          value & fetch_value_from_ar_object(column_name) == value
        }

        # set this bit
        #
        # * Author: Aman
        # * Date: 11/10/2017
        # * Reviewed By: Sunil
        #
        define_method("set_#{attribute}") {
          current_val = fetch_value_from_ar_object(column_name)
          final_val = current_val | value
          self.send("#{column_name}=", final_val)
        }

        # unset this bit
        #
        # * Author: Aman
        # * Date: 11/10/2017
        # * Reviewed By: Sunil
        #
        define_method("unset_#{attribute}") {
          current_val = fetch_value_from_ar_object(column_name)
          final_val = current_val & ~value
          self.send("#{column_name}=", final_val)
        }

      end

    end

  end

  class_methods do

  end

end