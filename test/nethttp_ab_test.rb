require 'test/unit'
require 'net/http'

require File.dirname(File.expand_path(__FILE__)) + '/../lib/requester.rb'

class NetHttpAbTest < Test::Unit::TestCase

  class TestResponse < Struct.new(:head, :body, :response_code)
  end

  class MySocketStub
    def initialize(body)
      @body = body
    end

    def closed?
      false
    end

    def read_all(from)
      @body
    end
  end

  def setup
    @requester = NethttpAb::Requester.new

    Net::HTTP.instance_eval do
      def self.get_response(url)
        body = File.read(File.join(File.dirname(File.expand_path(__FILE__)), 'resources', url.path))     
        resp = Net::HTTPOK.new(Net::HTTP.version_1_2, '200', '')
        resp.reading_body(MySocketStub.new(body), true){}
        resp.body = body
        resp
      end
    end
  end

  def test_simple
    @requester.url = "http://localhost/index.html"
    @requester.concurrent_users = 3
    @requester.num_of_requests = 10
    @requester.follow_links = false

    @requester.proceed

    assert_equal 10, @requester.successfull_requests
    assert_equal 0, @requester.failed_requests
  end

  def test_follow_links
    @requester.url = "http://localhost/links.html"
    @requester.concurrent_users = 3
    @requester.follow_links = true

    @requester.proceed

    assert_equal 5, @requester.successfull_requests
    assert_equal 0, @requester.failed_requests
  end
end
