require 'rubygems'
require 'net/http'
require 'uri'

require 'nokogiri' # we could follow links on the pages if there's --follow-links=2 option

# nethttperf -n100 -c3 http://localhost/messages

require 'benchmark'
require 'thread'

url = URI.parse("http://localhost:3000/messages")

NUM_OF_CONCURRENT_THREADS = 3
NUM_OF_REQUESTS           = 100

@failed_requests   = 0
@success_requests  = 0

@total_time = 0.0
@responce_length = 0

threads = []

NUM_OF_CONCURRENT_THREADS.times do 
	thread = Thread.new do
		begin
		  @total_time += Benchmark.realtime do
		    responce = Net::HTTP.get(url)
		    @responce_length += responce.length
		    @success_requests += 1
		  end
		rescue Errno::ECONNREFUSED => e
		  p e.message.inspect
		  @failed_requests += 1
		rescue => e
		  p e.message.inspect
		  @failed_requests += 1
		end
	end
  threads << thread
end

threads.each{|thread| thread.join}

print "Failed requests: #{@failed_requests}\n"
printf "Total time: %.03f s\n", @total_time
printf "Average time per request: %.03f s\n", @total_time / @success_requests.to_f
printf "Requests per minute: %.01f rpm\n", 1.0 / (@total_time / @success_requests.to_f)
