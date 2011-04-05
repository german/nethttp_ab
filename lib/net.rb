require 'net/http'
require 'uri'

module NethttpAb
  module Utility
    def get_http_session(url)
      http = Net::HTTP.new(url.host, url.port)
      if url.scheme == "https"
        http.use_ssl = true
        http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      end

      http.read_timeout = 10
      http.open_timeout = 10

      http_opened_session = http.start

      http_opened_session
    end
  end
end
