require 'test/unit'
require 'net/http'
require 'mocha'

require File.dirname(File.expand_path(__FILE__)) + '/../lib/requester.rb'

class TestResponse < Struct.new(:head, :body, :response_code)
end

class OpenSession
  def request(url)
    body = File.read(File.join(File.dirname(File.expand_path(__FILE__)), 'resources', url.path))
    TestResponse.new("head", body, 200)
  end
end

class NetHttpAbTest < Test::Unit::TestCase
  def setup
    Net::HTTP.any_instance.stubs(:start).returns(OpenSession.new)
    @requester = NethttpAb::Requester.new
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
