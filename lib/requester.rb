require 'benchmark'
require 'thread'
require 'nokogiri' # we could follow links on the pages if there's --follow-links=2 option

require File.dirname(File.expand_path(__FILE__)) + '/requests_queue'
require File.dirname(File.expand_path(__FILE__)) + '/simple_requests_queue'
require File.dirname(File.expand_path(__FILE__)) + '/net'

class Requester
  attr_accessor :successfull_requests
  attr_accessor :failed_requests

  def initialize
    @response_length = 0
    @total_time = 0.0
    @threads = []
    @mutex = Mutex.new
    @failed_requests   = 0
    @successfull_requests  = 0
    @follow_links = false
  end

  def concurrent_users=(num)
    @concurrent_users = num
  end

  def num_of_requests=(num)
    @num_of_requests = num
  end

  def follow_links=(flag)
    @follow_links = flag
  end

  def url=(link)
    @url = URI.parse(link)
    @url.path = '/' if @url.path == "" # ensure we requesting main page (if url is like http://google.com)
  end

  def print_stats
    print "Failed requests: #{@failed_requests}\n"
    print "Succeeded requests: #{@successfull_requests}\n\n"

    print "Total response length: #{@response_length} bytes\n"
    if @successfull_requests > 0
      print "Recieved characters per one page: #{@response_length / @successfull_requests} bytes\n\n"
    end

    printf "Total time: %.03f s\n", @total_time
    printf "Average time per request: %.03f s\n", @total_time / @successfull_requests.to_f
    printf "Requests per second: %.01f rps\n", 1.0 / (@total_time / @successfull_requests.to_f)
  end

  def proceed  
    prepare_queue     
    start_threads
  end

  private

    def prepare_queue
      @requests_queue = if @follow_links
        # get all links to benchmark as user behavior
        http_opened_session = get_http_session(@url)
        req = Net::HTTP::Get.new(@url.path)
        response = http_opened_session.request(req)
        doc = Nokogiri::HTML(response.body)
        #puts doc.css('a').map{|el| el.attr('href')}.inspect
        local_links = doc.css('a').reject{|el| el.attr('rel') == 'nofollow'}.select{|el| el.attr('href').match(Regexp.escape(@url.host)) || (el.attr('href') !~ /^(http|www|javascript)/) }
        local_links.map!{|el| el.attr('href')}
        local_links.uniq!
        print "Found #{local_links.inspect} local links\n"
        RequestsQueue.new(local_links)
      else
        SimpleRequestsQueue.new(@num_of_requests)         
      end
    end

    def start_threads
      @concurrent_users.times do
        http_opened_session = get_http_session(@url)

        @threads << Thread.new do
          while !@requests_queue.empty? do
            # lock request in order to avoid sharing same request by two threads and making more requests then specified
            if next_url = @requests_queue.lock_next_request
              req = if @follow_links
                next_url_parsed = URI.parse(next_url)
                Net::HTTP::Get.new(next_url_parsed.path)
              else
                Net::HTTP::Get.new(@url.path)
              end

              @total_time += Benchmark.realtime do
                begin
                  response = http_opened_session.request(req)
                  @mutex.synchronize do
                    @response_length += response.body.length
                    @successfull_requests += 1
                    @requests_queue.release_locked_request(next_url)
                  end 
                rescue Net::HTTPBadResponse => e
                  print "An error occured: #{e.message}\n"
                  @failed_requests += 1
                rescue Timeout::Error => e
                  print "Timeout error for #{next_url}\n"
                  @failed_requests += 1
                rescue => e
                  print "An error occured: #{e.message}\n"
                  @failed_requests += 1
                end
              end
            else
              # exit current thread since there's no available requests in requests_queue
              Thread.exit      
            end
          end
        end
      end

      @threads.each{|thread| thread.join}
    end
end