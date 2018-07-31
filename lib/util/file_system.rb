module Util
  class FileSystem

    require 'zip'

    def self.create_zip(folder, file_extension_to_zip)
      zipfile_name = "#{folder}.zip"

      Zip::File.open(zipfile_name, Zip::File::CREATE) do |zipfile|
        Dir.glob("#{folder}/*.#{file_extension_to_zip}").each do |filename|
          zipfile.add(File.basename(filename), filename)
        end
      end
      {filepath: zipfile_name}
    end

    def self.delete_file(filepath)
      File.delete(filepath)
    end

    def self.check_and_create_directory_for_file(local_file_path)
      dir = File.dirname(local_file_path)
      check_and_create_directory(dir)
      dir
    end

    def self.check_and_create_directory(dir)
      FileUtils.mkdir_p(dir) unless File.directory?(dir)
      dir
    end

    def self.delete_directory(dir)
      FileUtils.rm_rf(dir)
    end

    def self.create_csv_zip(folder)
      create_zip(folder, 'csv')
    end

  end
end

