module GlobalConstant

  class NationalityCountry

    # GlobalConstant::NationalityCountry

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
          key = sp[0]
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
          key = sp[0]
          value = sp[1]
          @nationality_iso_mapping[key] = value
        end
      end

      @nationality_iso_mapping

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
      @fetch_file_contents ||= File.open("#{Rails.root}/lib/Nationality_and_country_mapping.csv",
                                         "rb").read.split("\n")
    end

  end

end