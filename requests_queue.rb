class RequestsQueue
  def initialize(num_of_requests)
    @num_of_requests = num_of_requests
    @num_of_locked   = 0
  end

  def lock_next_request
    if @num_of_requests > @num_of_locked
      @num_of_locked += 1
      true
    else
      false
    end
  end

  def release_locked_request
    @num_of_locked -= 1 if @num_of_locked > 0    
    @num_of_requests -= 1 if @num_of_requests > 0
  end

  def empty?
    @num_of_requests == 0
  end
end
