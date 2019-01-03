require 'net/http'
require 'json'
require 'pp'
@request_class = nil
@api_url = nil

@names = ["narendra", "nirav", "alpesh", "gajanan", "suresh", "nitesh", "ramesh", "kunal", "krishna", "akshay"]

class CaseSensitiveString < String
  def downcase
    self
  end

  def capitalize
    self
  end

  def to_s
    self
  end
end


def get_request(endpoint, params= {}, key)


end

def country_list

  @api_url = "https://api1.uat.c6-intelligence.com/api/v2_1/api/countries"
  uri = URI(@api_url)

  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true
  http.verify_mode = OpenSSL::SSL::VERIFY_NONE
  req_obj = Net::HTTP::Get.new(uri.request_uri)
  headers = {"Content-Type" => 'application/json', "Host" => "api1.uat.c6-intelligence.com"}
  headers[CaseSensitiveString.new('apiKey')] = "59d40a35-33f6-4e24-a5d2-8fcf876b73ee"

  headers.each do |h, v|
    req_obj[h] = v
  end




  #http.set_debug_output($stdout)
  http_response = http.request(req_obj)

  res = http_response.body
  res = JSON.parse res
  pp res

end



def post_request(endpoint, params = {}, key)
  @api_url = "https://api1.uat.c6-intelligence.com/api/v2_1/api/persons/" + endpoint
  uri = URI(@api_url)

  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true
  http.verify_mode = OpenSSL::SSL::VERIFY_NONE
  req_obj = Net::HTTP::Post.new(uri.request_uri)
  headers = {"Content-Type" => 'application/json', "Host" => "api1.uat.c6-intelligence.com"}
  headers[CaseSensitiveString.new('apiKey')] = "59d40a35-33f6-4e24-a5d2-8fcf876b73ee"

  headers.each do |h, v|
    req_obj[h] = v
  end
  body = params

  { "Threshold"=> "40","PEP" => true, "PreviousSanctions" => true, "CurrentSanctions" => true, "LawEnforcement" => true,
    "FinancialRegulator" => true, "Insolvency" => true, "DisqualifiedDirector" => true, "AdverseMedia" => true,
    "Forename" => 'rahul', "Surname" => "gandhi", "City" => "New Delhi" }


  req_obj.body = body.to_json

  # http.set_debug_output($stdout)
  http_response = http.request(req_obj)

  res = http_response.body





end


def put_request(endpoint, params = {}, key)






end

def person_search(i)
  @api_url = "https://api1.uat.c6-intelligence.com/api/v2_1/api/persons/search"
  uri = URI(@api_url)

  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true
  http.verify_mode = OpenSSL::SSL::VERIFY_NONE
  req_obj = Net::HTTP::Post.new(uri.request_uri)
  headers = {"Content-Type" => 'application/json', "Host" => "api1.uat.c6-intelligence.com"}
  headers[CaseSensitiveString.new('apiKey')] = "59d40a35-33f6-4e24-a5d2-8fcf876b73ee"

  headers.each do |h, v|
    req_obj[h] = v
  end
  body = { "Threshold"=> "40","PEP" => false, "PreviousSanctions" => false, "CurrentSanctions" => false, "LawEnforcement" => true,
           "FinancialRegulator" => true, "Insolvency" => true, "DisqualifiedDirector" => true, "AdverseMedia" => false,
           "Forename" => 'Elizabeth', "Surname" => "Dagg" }
  req_obj.body = body.to_json

  #http.set_debug_output($stdout)
  http_response = http.request(req_obj)

  res = http_response.body


end


def person_monitor

  @api_url = "https://api1.uat.c6-intelligence.com/monitorApi/v1_0/api/persons"
  uri = URI(@api_url)

  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true
  http.verify_mode = OpenSSL::SSL::VERIFY_NONE
  req_obj = Net::HTTP::Post.new(uri.request_uri)
  headers = {"Content-Type" => 'application/json', "Host" => "api1.uat.c6-intelligence.com"}
  headers[CaseSensitiveString.new('apiKey')] = "4796b10a-44b7-4a82-b41c-a5230cc31f75"

  headers.each do |h, v|
    req_obj[h] = v
  end
  body = {
      "forename" => 'Kumar', "surname" => "Singh", "countryName" => "India",  "uniqueId"=> "123223452", "sourceName"=> "Aman"
  }
  req_obj.body = body.to_json

  #http.set_debug_output($stdout)
  http_response = http.request(req_obj)

  res = http_response.body
  puts res





end

def get_person_monitor

  @api_url = "https://api1.uat.c6-intelligence.com/monitorApi/v1_0/api/persons/0/100"
  uri = URI(@api_url)

  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true
  http.verify_mode = OpenSSL::SSL::VERIFY_NONE
  req_obj = Net::HTTP::Get.new(uri.request_uri)
  headers = {"Content-Type" => 'application/json', "Host" => "api1.uat.c6-intelligence.com"}
  headers[CaseSensitiveString.new('apiKey')] = "4796b10a-44b7-4a82-b41c-a5230cc31f75"

  headers.each do |h, v|
    req_obj[h] = v
  end

  #http.set_debug_output($stdout)
  http_response = http.request(req_obj)

  res = http_response.body
  res = JSON.parse res
  pp res



end


def update_person

  @api_url = "https://api1.uat.c6-intelligence.com/monitorApi/v1_0/api/persons?uniqueId=123223445"
  uri = URI(@api_url)

  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true
  http.verify_mode = OpenSSL::SSL::VERIFY_NONE
  req_obj = Net::HTTP::Put.new(uri.request_uri)
  headers = {"Content-Type" => 'application/json', "Host" => "api1.uat.c6-intelligence.com"}
  headers[CaseSensitiveString.new('apiKey')] = "4796b10a-44b7-4a82-b41c-a5230cc31f75"

  headers.each do |h, v|
    req_obj[h] = v
  end
  body = {
      "forename"=> "Donald", "surname"=> "trump",  "uniqueId"=> "123223445", "country"=> "India",
      "nationalityName"=> "Indian", "sourceName"=> "Aman", "dob"=> "1955-09-17", "yob"=> 1955
  }
  req_obj.body = body.to_json

  #http.set_debug_output($stdout)
  http_response = http.request(req_obj)

  res = http_response.body
  puts res

end


def monitored_matches
  @api_url = "https://api1.uat.c6-intelligence.com/monitorApi/v1_0/api/worklist/0/100?source=Aman"
  uri = URI(@api_url)

  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true
  http.verify_mode = OpenSSL::SSL::VERIFY_NONE
  req_obj = Net::HTTP::Get.new(uri.request_uri)
  headers = {"Content-Type" => 'application/json', "Host" => "api1.uat.c6-intelligence.com"}
  headers[CaseSensitiveString.new('apiKey')] = "4796b10a-44b7-4a82-b41c-a5230cc31f75"

  headers.each do |h, v|
    req_obj[h] = v
  end
  http_response = http.request(req_obj)

  res = http_response.body
  res = JSON.parse res
  pp res
end


def pdf_download
  puts "i ma"
  @api_url = "https://api1.uat.c6-intelligence.com/api/v2_1/api/persons/profilePDF/344625"
  uri = URI(@api_url)

  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true
  http.verify_mode = OpenSSL::SSL::VERIFY_NONE
  req_obj = Net::HTTP::Post.new(uri.request_uri)
  headers = {"Content-Type" => 'application/json', "Host" => "api1.uat.c6-intelligence.com"}
  headers[CaseSensitiveString.new('apiKey')] = "59d40a35-33f6-4e24-a5d2-8fcf876b73ee"

  headers.each do |h, v|
    req_obj[h] = v
  end
  #http.set_debug_output($stdout)
  http_response = http.request(req_obj)
  res = http_response.body
  get_pdf_file(res)
end



def get_pdf_file(res, filepath="sample.pdf")
  open(filepath, "wb") do |file|
    file.write(res)
  end
end




#pdf_download

# $count = 0
# start = Time.now
# while $count < 10 do
#   person_search($count)
#   $count += 1
# end
# end_time = Time.now
# diff = end_time - start
#
# puts ("Time taken for 10 search requests #{diff.to_i}")

res = person_search(0)
res = JSON.parse res
puts res
# # @c = 0
# while @c < res['matches'].count
#   puts "--------------------------------------------------------------------------------------------------------"
#   pp res['matches'][@c]
#   @c += 1
#   puts "--------------------------------------------------------------------------------------------------------"
# end

# person_monitor
# get_person_monitor
# update_person
# monitored_matches
#
# country_list
#
#
#