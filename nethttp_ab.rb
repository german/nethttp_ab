#!/usr/bin/env ruby
require 'rubygems'
require 'net/http'
require 'uri'
require 'trollop'
require 'benchmark'
require 'thread'
require 'nokogiri' # we could follow links on the pages if there's --follow-links=2 option

# USAGE:
# ./nethttperf.rb -n 100 -c 3 http://www.yoursite.com

opts = Trollop::options do
  opt :concurrent_threads, "Number of concurrent threads", :default => 3, :short => 'c'
  opt :requests, "Total number of requests", :default => 10, :short => 'n'
end

url_to_benchmark = "http://localhost:3000/"

# search for the url to perform benchmarking on
# we don't use trollop here since I need to specify something like --url=http://mysite.com to get the url
ARGV.each do |arg|
  url_to_benchmark = arg if arg =~ /http:\/\/|www\./
end

url = URI.parse(url_to_benchmark)

NUM_OF_CONCURRENT_THREADS = (opts[:concurrent_threads] || 3).to_i

@num_of_requests           = (opts[:requests] || 10).to_i

@failed_requests   = 0
@success_requests  = 0

@total_time = 0.0
@response_length = 0

threads = []
@mutex = Mutex.new

NUM_OF_CONCURRENT_THREADS.times do |thread_id| 
	threads << Thread.new(thread_id) do
		begin
      while @num_of_requests > 0 do
        #print "@num_of_requests - #{@num_of_requests} from #{thread_id}\n"
  		  @total_time += Benchmark.realtime do
	  	    responce = Net::HTTP.get(url)
	        @response_length += responce.length
          @success_requests += 1

          @mutex.synchronize do            
            @num_of_requests -= 1
          end
        end
		  end
		rescue Errno::ECONNREFUSED => e
		  p e.message.inspect
		  @failed_requests += 1
		rescue => e
		  p e.message.inspect
		  @failed_requests += 1
		end
	end
end

threads.each{|thread| thread.join}

print "Failed requests: #{@failed_requests}\n"
print "Succeeded requests: #{@success_requests}\n\n"

print "Total response length: #{@response_length} bytes\n"
print "Recieved characters per one page: #{@response_length / @success_requests} bytes\n\n"

printf "Total time: %.03f s\n", @total_time
printf "Average time per request: %.03f s\n", @total_time / @success_requests.to_f
printf "Requests per minute: %.01f rpm\n", 1.0 / (@total_time / @success_requests.to_f)
