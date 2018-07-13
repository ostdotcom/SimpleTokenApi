module Util
  module CsvHelper

    require 'csv'

    CSV_BATCH_SIZE = 10000

    def zip_folder
      write_csv if csv.lineno > 0
      create_zip
    end

    def delete_local_files
      FileUtils.remove_dir(csv_file_folder_full_path)
      Util::FileSystem.delete_file("#{csv_file_folder_full_path}.zip")
    end

    def create_write_dir
      Util::FileSystem.check_and_create_directory_for_file(csv_file_name)
    end

    def csv
      @csv ||= fetch_csv
    end

    def csv_batch_counter
      @csv_batch_counter ||= 1
    end

    def c_add(element)
      if csv.lineno >= CSV_BATCH_SIZE
        write_csv
      end
      csv << element
    end

    def write_csv
      create_write_dir if csv_batch_counter == 1
      Rails.logger.info {"Creating CSV - #{csv_file_name}"}
      File.write(csv_file_name, csv.string)
      @csv = nil
      @csv_batch_counter += 1
    end

    def csv_file_name
      "#{csv_file_folder_full_path}/#{csv_batch_counter}.csv"
    end

    def create_zip
      Rails.logger.info {"Creating ZIP - #{csv_file_folder_full_path}"}
      Util::FileSystem.create_csv_zip(csv_file_folder_full_path)
    end

    def fetch_csv
      c = CSV.new('')
      c << csv_headers
      c
    end

    def total_rows_written
      csv.lineno + ((csv_batch_counter - 1) * CSV_BATCH_SIZE)
    end

    def csv_headers
      fail 'csv_headers method not implemented'
    end

    def csv_file_folder_full_path
      fail 'unimplemented'
    end

  end
end