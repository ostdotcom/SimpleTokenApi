module GlobalConstant

  class NationalityCountry

    # GlobalConstant::NationalityCountry

    # Usa States with space regex to handle multiple or 0 spaces
    #
    # * Author: Tejas
    # * Date: 02/07/2018
    # * Reviewed By:
    #
    # @return [String]
    #
    def self.regex_usa_states
      @regex_usa_states ||= begin
        arr = []
        usa_states.each do |state|
          arr << Util::CommonValidateAndSanitize.get_words_regex_for_multi_space_support(state)
        end
        arr
      end
    end

    # canada States with space regex to handle multiple or 0 spaces
    #
    # * Author: Tejas
    # * Date: 02/07/2018
    # * Reviewed By:
    #
    # @return [String]
    #
    def self.regex_canada_states
      @regex_canada_states ||= begin
        arr = []
        canada_states.each do |state|
          arr << Util::CommonValidateAndSanitize.get_words_regex_for_multi_space_support(state)
        end
        arr
      end
    end

    # Usa States
    #
    # * Author: Tejas
    # * Date: 02/07/2018
    # * Reviewed By:
    #
    # @return [Array]
    #
    def self.usa_states
      ['USA', 'United States Minor Outlying Islands', 'United States of America',
       'Alabama', 'Alaska', 'Arizona', 'Arkansas', 'California', 'Colorado', 'Connecticut', 'Delaware', 'Florida',
       'Georgia', 'Hawaii', 'Idaho', 'Illinois', 'Indiana', 'Iowa', 'Kansas', 'Kentucky', 'Louisiana', 'Maine', 'Maryland',
       'Massachusetts', 'Michigan', 'Minnesota', 'Mississippi', 'Missouri', 'Montana Nebraska', 'Nevada', 'New Hampshire',
       'New Jersey', 'New Mexico', 'New York', 'Dakota', 'Ohio', 'Oklahoma', 'Oregon',
       'Carolina', 'Tennessee', 'Texas', 'Utah', 'Vermont', 'Virginia',
       'Washington', 'West Virginia', 'Wisconsin', 'Wyoming', 'CAROLINA', 'Pennsylvania', 'Rhode Island']
    end

    # Canada States
    #
    # * Author: Tejas
    # * Date: 10/07/2018
    # * Reviewed By:
    #
    # @return [Array]
    #
    def self.canada_states
      ['Alberta', 'British Columbia', 'Manitoba', 'New Brunswick', 'Newfoundland and Labrador	',
       'Nova Scotia', 'Ontario', 'Prince Edward Island', 'Quebec', 'Saskatchewan', 'Northwest Territories',
       'Nunavut', 'Yukon']
    end

    # Nationality Country Map
    #
    # * Author: Tejas
    # * Date: 09/07/2018
    # * Reviewed By:
    #
    # @return [Hash]
    #

    def self.nationality_country_map
      generate_nationality_country_map
    end

    # Nationality Iso Map
    #
    # * Author: Tejas
    # * Date: 09/07/2018
    # * Reviewed By:
    #
    # @return [Hash]
    #

    def self.nationality_iso_map
      generate_nationality_iso_map
    end


    # Generate Nationality Country Map
    #
    # * Author: Tejas
    # * Date: 09/07/2018
    # * Reviewed By:
    #
    # @return [Hash] nationality_country_mapping
    #

    def self.generate_nationality_country_map
      @nationality_country_mapping ||= {}
      if @nationality_country_mapping.blank?
        fetch_country_nationality_mapping.each do |row|
          sp = row.gsub("\r", "").split(",")
          key = sp[0].upcase
          val = sp.drop(2)
          @nationality_country_mapping[key] = val
        end
      end

      @nationality_country_mapping

    end

    # Generate Nationality Iso Map
    #
    # * Author: Tejas
    # * Date: 09/07/2018
    # * Reviewed By:
    #
    # @return [Hash] nationality_iso_mapping
    #

    def self.generate_nationality_iso_map
      @nationality_iso_mapping ||= {}
      if @nationality_iso_mapping.blank?
        fetch_country_nationality_mapping.each do |row|
          sp = row.gsub("\r", "").split(",")
          key = sp[0].upcase
          value = sp[1].upcase
          @nationality_iso_mapping[key] = value
        end
      end

      @nationality_iso_mapping

    end

    def self.generate_nationality_iso_map
      mapping ||= {}

      a.each do |row|
        sp = row.gsub("\r", "").split(",")
        key = sp[0].upcase
        mapping[key] = sp
      end

    end

    # Fetch Country Nationality Mapping
    #
    # * Author: Tejas
    # * Date: 09/07/2018
    # * Reviewed By:
    #
    # @return Array[String] fetch_file_contents
    #

    def self.fetch_country_nationality_mapping
      @fetch_file_contents ||= File.open("#{Rails.root}/config/nationality_and_country_mapping.csv",
                                         "rb").read.split("\n")
    end

  end

end