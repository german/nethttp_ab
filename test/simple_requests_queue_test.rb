require 'test/unit'
require File.dirname(File.expand_path(__FILE__)) + '/../lib/simple_requests_queue.rb'

class SimpleRequestQueueTest < Test::Unit::TestCase
  def test_initial
    queue = SimpleRequestsQueue.new(3)
    assert !queue.empty?

    3.times { assert queue.lock_next_request }

    2.times { queue.release_locked_request }

    assert !queue.empty?

    queue.release_locked_request

    assert queue.empty?

    assert !queue.lock_next_request
  end
end
