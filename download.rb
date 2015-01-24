require 'mechanize'
require 'open-uri'
require 'json'

request_url = 'https://www.kimonolabs.com/api/1wk8fcdo?apikey=5f7ad99b9fc33fe2a01cf880579c6530'

buffer = open(request_url).read

result = JSON.parse(buffer)

file_name = "links.html"

File.open(file_name, 'w') {|f| f.write("<html><body>")}

result['results']['Movie'].each_with_index do |x, i|
	File.open(file_name, 'a') {|f| f.write("<a href='#{x['DownloadLink']}' target='_blank'>link #{i+1}</a><br>")}
end

File.open(file_name, 'a') {|f| f.write("</html></body>")}