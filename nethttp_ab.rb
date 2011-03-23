#!/usr/bin/env ruby
require 'rubygems'
require 'trollop'
require 'benchmark'
require 'thread'
require './lib/net.rb'
# USAGE:
# ./nethttp_ab.rb -n 100 -c 3 http://www.yoursite.com
# OR 
# ./nethttp_ab.rb --follow http://localhost:3000

opts = Trollop::options do
  opt :concurrent_threads, "Number of concurrent threads", :default => 3, :short => 'c'
  opt :requests, "Total number of requests", :default => 10, :short => 'n'
  opt :follow, "Whether to follow links from received pages (emulating real user)", :default => false, :short => 'f'  
end

if opts[:follow]
  require 'nokogiri' # we could follow links on the pages if there's --follow-links=2 option
  require './lib/requests_queue'
else
  require './lib/simple_requests_queue'
end

url_to_benchmark = "http://localhost:3000/"
# search for the url to perform benchmarking on
# we don't use trollop here since I don't like to specify --url=http://mysite.com to get the url
ARGV.each do |arg|
  url_to_benchmark = arg if arg =~ /https?:\/\/|www\./
end

url = URI.parse(url_to_benchmark)
url.path = '/' if url.path == "" # ensure we requesting main page (if url is like http://google.com)

NUM_OF_CONCURRENT_THREADS = (opts[:concurrent_threads] || 3).to_i

failed_requests   = 0
success_requests  = 0

total_time = 0.0
response_length = 0

threads = []
mutex = Mutex.new

requests_queue = if opts[:follow]
  # get all links to benchmark as user behavior
  http_opened_session = get_http_session(url)
  req = Net::HTTP::Get.new(url.path)
  response = http_opened_session.request(req)
  doc = Nokogiri::HTML(response.body)
  #puts doc.css('a').map{|el| el.attr('href')}.inspect
  local_links = doc.css('a').reject{|el| el.attr('rel') == 'nofollow'}.select{|el| el.attr('href').match(Regexp.escape(url.host)) || (el.attr('href') !~ /^(http|www|javascript)/) }
  local_links.map!{|el| el.attr('href')}
  local_links.uniq!
  print "Found #{local_links.inspect} local links\n"
  RequestsQueue.new(local_links)
else
  SimpleRequestsQueue.new((opts[:requests] || 10).to_i)         
end

NUM_OF_CONCURRENT_THREADS.times do
  # req = Net::HTTP::Get.new(url.path)

  http_opened_session = get_http_session(url)

  threads << Thread.new do
    while !requests_queue.empty? do
      # lock request in order to avoid sharing same request by two threads and making more requests then specified
      if next_url = requests_queue.lock_next_request
        req = if opts[:follow]
          next_url_parsed = URI.parse(next_url)
          Net::HTTP::Get.new(next_url_parsed.path)
        else
          Net::HTTP::Get.new(url.path)
        end

        total_time += Benchmark.realtime do
          begin
            response = http_opened_session.request(req)
            mutex.synchronize do
              response_length += response.body.length
              success_requests += 1
              requests_queue.release_locked_request(next_url)
            end 
          rescue Net::HTTPBadResponse => e
            print "An error occured: #{e.message}\n"
            failed_requests += 1
          rescue Timeout::Error => e
            print "Timeout error for #{next_url}\n"
            failed_requests += 1
          #rescue => e
          #  print "An error occured: #{e.message}\n"
          #  failed_requests += 1
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
printf "Requests per second: %.01f rps\n", 1.0 / (total_time / success_requests.to_f)
