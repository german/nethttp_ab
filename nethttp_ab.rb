#!/usr/bin/env ruby
require 'rubygems'
require 'net/http'
require 'uri'
require 'trollop'
require 'benchmark'
require 'thread'
#require 'nokogiri' # we could follow links on the pages if there's --follow-links=2 option
require './requests_queue'
# USAGE:
# ./nethttperf.rb -n 100 -c 3 http://www.yoursite.com

opts = Trollop::options do
  opt :concurrent_threads, "Number of concurrent threads", :default => 3, :short => 'c'
  opt :requests, "Total number of requests", :default => 10, :short => 'n'
  opt :follow, "Whether to follow links from received pages", :default => false, :short => 'f'
end

url_to_benchmark = "http://localhost:3000/"

# search for the url to perform benchmarking on
# we don't use trollop here since I don't like to specify --url=http://mysite.com to get the url
ARGV.each do |arg|
  url_to_benchmark = arg if arg =~ /http:\/\/|www\./
end

url = URI.parse(url_to_benchmark)

NUM_OF_CONCURRENT_THREADS = (opts[:concurrent_threads] || 3).to_i

requests_queue = RequestsQueue.new((opts[:requests] || 10).to_i)

failed_requests   = 0
success_requests  = 0

total_time = 0.0
response_length = 0

threads = []
@mutex = Mutex.new

NUM_OF_CONCURRENT_THREADS.times do |thread_id| 
  threads << Thread.new(thread_id) do
    while !requests_queue.empty? do
      if requests_queue.lock_next
        total_time += Benchmark.realtime do
          begin
            response = Net::HTTP.get(url)
            @mutex.synchronize do
              response_length += response.length
              success_requests += 1
              requests_queue.release_locked
            end
          rescue Errno::ECONNREFUSED => e
	    p e.message.inspect
	    failed_requests += 1
	  rescue => e
	    p e.message.inspect
	    failed_requests += 1
	  end
	end
      else
        # exit current thread since there's no available requests in requests_queue
        Thread.exit
      end
    end
  end
end

threads.each{|thread| thread.join}

print "Failed requests: #{failed_requests}\n"
print "Succeeded requests: #{success_requests}\n\n"

print "Total response length: #{response_length} bytes\n"
if success_requests > 0
  print "Recieved characters per one page: #{response_length / success_requests} bytes\n\n"
end

printf "Total time: %.03f s\n", total_time
printf "Average time per request: %.03f s\n", total_time / success_requests.to_f
printf "Requests per minute: %.01f rpm\n", 1.0 / (total_time / success_requests.to_f)
