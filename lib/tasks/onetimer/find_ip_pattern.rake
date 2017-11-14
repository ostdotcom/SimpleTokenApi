namespace :onetimer do

  # rake RAILS_ENV=development onetimer:find_ip_pattern threshold=100 file_path='/Users/kedarchandrayan/workspace/rails/simple_token/simple_token_api/lib/tasks/onetimer/data/ip_log.txt'

  task :find_ip_pattern => :environment do

    threshold = ENV['threshold'].to_i
    file_path = '/mnt/nginx/logs/ips.log'
    log_file_path = '/mnt/nginx/logs/access-web.log'

    system('cat ' + log_file_path + ' | awk -v FS="(PROXY=|- HTTP_VIA)" \'{print $2}\' | awk -v FS="\"|," \'{print $2}\' | sort | uniq -c | sort -n > ' + file_path)

    ip_patterns = []

    File.open(file_path, "r").each_line do |line|
      line = line.strip

      line_parts = line.split(' ')

      curr_count = line_parts[0].to_i

      next if curr_count < threshold

      ip = line_parts[1]

      ip_parts = ip.split('.')

      curr_pattern = ip_parts[0] + '.' + ip_parts[1][0, 2]

      next if ['10.20', '114.14'].include?(curr_pattern)

      ip_patterns << ip_parts[0] + '\.' + ip_parts[1][0, 2]

    end

    puts 'tail -f ' + log_file_path + ' | grep "' + ip_patterns.uniq.join('\|') + '"'

  end

end
