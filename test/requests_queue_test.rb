require 'test/unit'
require File.dirname(File.expand_path(__FILE__)) + '/../lib/requests_queue.rb'

class RequestQueueTest < Test::Unit::TestCase
  def test_initial
    urls = ["http://www.google.com", "http://www.ruby-lang.com", "http://www.github.com", "http://www.def-end.com"]

    queue = NethttpAb::RequestsQueue.new urls
    assert !queue.empty?
 
    4.times { assert queue.lock_next_request }

    3.times { |i| queue.release_locked_request(urls[i]) }

    assert !queue.empty?

    queue.release_locked_request(urls[3])

    assert queue.empty?

    assert !queue.lock_next_request
  end
end
