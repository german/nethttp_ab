module NethttpAb
  class RequestsQueue
    def initialize(url_array)
      @urls_queue = url_array
      @locked_urls = []

      @num_of_requests = url_array.size
      @num_of_locked   = 0
    end

    def lock_next_request
      if @num_of_requests > @num_of_locked
        @num_of_locked += 1
        @locked_urls << @urls_queue.shift
        @locked_urls.last
      end
    end

    def release_locked_request(url)
      if @num_of_locked > 0
        @num_of_locked -= 1
        @locked_urls.delete_if{|u| u == url}
      end

      @num_of_requests -= 1 if @num_of_requests > 0
    end

    def empty?
      @num_of_requests == 0
    end
  end
end
