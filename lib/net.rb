require 'net/http'
require 'uri'

def get_http_session(url)
  http = Net::HTTP.new(url.host, url.port)
  if url.scheme == "https"
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE
  end

  http.read_timeout = 10
  http.open_timeout = 10

  begin
    http_opened_session = http.start
  rescue OpenSSL::SSL::SSLError => e
    p "The url you provided is wrong, please check is it really ssl encrypted"
  rescue Errno::ECONNREFUSED => e
    p "Connection error, please check your internet connection or make sure the server is running (it it's local)"
  end

  http_opened_session
end
