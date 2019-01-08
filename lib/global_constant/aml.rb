# frozen_string_literal: true
module GlobalConstant

  class Aml
    # GlobalConstant::Admin

    class << self

      ### Status Start ###

      def default_query_data

        {
        "Threshold"=>70,
        "PEP"=>true,
        "PreviousSanctions"=>true,
        "CurrentSanctions"=>true,
        "LawEnforcement"=>true,
        "FinancialRegulator"=>true,
        "Insolvency"=>true,
        "DisqualifiedDirector"=>true,
        "AdverseMedia"=>true
        }
      end

      def query_data_mapping
        {
            "first_name" => "Forename",
            "last_name" => "Surname",
            "birthdate" => "DateOfBirth",
            "country" => "Country",
            "postal_code" => "Postcode",
            "city" => "City",
            "street_address" => "Address"
        }

      end

    end

  end

end
