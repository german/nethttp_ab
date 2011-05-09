require 'benchmark'
require 'thread'
require 'net/http'

require File.dirname(File.expand_path(__FILE__)) + '/requests_queue'
require File.dirname(File.expand_path(__FILE__)) + '/simple_requests_queue'

module NethttpAb
  class Requester

    attr_accessor :successfull_requests
    attr_accessor :failed_requests

    #URL_REGEXP = /^(https?:\/\/)?(?:[a-zA-Z0-9-]+\.)+[a-zA-Z]{2,4}/

    # list of all available TLD domains
    # http://data.iana.org/TLD/tlds-alpha-by-domain.txt
    URL_REGEXP = /^(https?:\/\/)?(?:[a-zA-Z0-9-]+\.)+(AC|AD|AE|AERO|AF|AG|AI|AL|AM|AN|AO|AQ|AR|ARPA|AS|ASIA|AT|AU|AW|AX|AZ|BA|BB|BD|BE|BF|BG|BH|BI|BIZ|BJ|BM|BN|BO|BR|BS|BT|BV|BW|BY|BZ|CA|CAT|CC|CD|CF|CG|CH|CI|CK|CL|CM|CN|CO|COM|COOP|CR|CU|CV|CX|CY|CZ|DE|DJ|DK|DM|DO|DZ|EC|EDU|EE|EG|ER|ES|ET|EU|FI|FJ|FK|FM|FO|FR|GA|GB|GD|GE|GF|GG|GH|GI|GL|GM|GN|GOV|GP|GQ|GR|GS|GT|GU|GW|GY|HK|HM|HN|HR|HT|HU|ID|IE|IL|IM|IN|INFO|INT|IO|IQ|IR|IS|IT|JE|JM|JO|JOBS|JP|KE|KG|KH|KI|KM|KN|KP|KR|KW|KY|KZ|LA|LB|LC|LI|LK|LR|LS|LT|LU|LV|LY|MA|MC|MD|ME|MG|MH|MIL|MK|ML|MM|MN|MO|MOBI|MP|MQ|MR|MS|MT|MU|MUSEUM|MV|MW|MX|MY|MZ|NA|NAME|NC|NE|NET|NF|NG|NI|NL|NO|NP|NR|NU|NZ|OM|ORG|PA|PE|PF|PG|PH|PK|PL|PM|PN|PR|PRO|PS|PT|PW|PY|QA|RE|RO|RS|RU|RW|SA|SB|SC|SD|SE|SG|SH|SI|SJ|SK|SL|SM|SN|SO|SR|ST|SU|SV|SY|SZ|TC|TD|TEL|TF|TG|TH|TJ|TK|TL|TM|TN|TO|TP|TR|TRAVEL|TT|TV|TW|TZ|UA|UG|UK|US|UY|UZ|VA|VC|VE|VG|VI|VN|VU|WF|WS|YE|YT|ZA|ZM|ZW)(\?|\Z|\/)(.*)?/i

    def initialize
      @response_length = 0
      @total_time = 0.0
      @threads = []
      @mutex = Mutex.new
      @failed_requests   = 0
      @successfull_requests  = 0
      @follow_links = false
      @follow_links_depth = 1
      @verbose = false
    end

    def verbose=(flag)
      @verbose = flag
    end

    def concurrent_users=(num)
      @concurrent_users = num
    end

    def num_of_requests=(num)
      @num_of_requests = num
    end

    def follow_links=(flag)
      @follow_links = flag
      # we could follow links on the pages if there's --follow-links=2 option
      puts 'follow_links mode' if @verbose && @follow_links
      require 'nokogiri' if @follow_links
    end

    def follow_links_depth=(depth)
      if depth > 0
        self.follow_links = true # set follow_links flag to true (if cli option was -f2 for example)
        @follow_links_depth = depth
      end
    end

    def url=(link)
      @url = URI.parse(link)
      @url.path = '/' if @url.path == "" # ensure we requesting main page (if url is like http://google.com)
    end

    def print_stats
      puts
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

      def extract_links_from(doc)
        doc.css('a').reject{|el| el.attr('rel') == 'nofollow' || el.attr('href') =~ /^javascript/ || el.attr('onclick')}
      end

      def select_local_links_from(all_links, parent_url_parsed)
        all_links.map!{|el| el.attr('href') }

        local_links = all_links.select{|href| href.match(Regexp.escape(parent_url_parsed.host)) || href !~ URL_REGEXP }

        # we assume that local_links now contains only links inner to tested site
        local_links.map! do |href|
          # a proper url should be constructed which then could be parsed by URI.parse
          if !href.match(Regexp.escape(parent_url_parsed.host))

            # relative links should be treated respectively
            path = if parent_url_parsed.path.count('/') > 1
              parent_url_parsed.path.gsub(parent_url_parsed.path[parent_url_parsed.path.rindex('/')..-1], '')
            else
              ''
            end

            href = if (href[0] == '/' && parent_url_parsed.host[-1] != '/') || (href[0] != '/' && parent_url_parsed.host[-1] == '/')
              "#{parent_url_parsed.scheme}://#{parent_url_parsed.host}#{path}#{href}"
            else
              "#{parent_url_parsed.scheme}://#{parent_url_parsed.host}#{path}/#{href}"
            end
          else
            href
          end             
        end
        local_links.uniq
      end

      def fetch_links_from(url, max_depth = 1, current_depth = 1)
        local_links = []

        # get all links to benchmark as user behavior
        response = begin
          Net::HTTP.get_response(url)
        rescue OpenSSL::SSL::SSLError => e
          puts("The url you provided is wrong, please check is it really ssl encrypted")
          exit
        rescue Errno::ECONNREFUSED => e
          puts("Connection error, please check your internet connection or make sure the server is running (it's local)")
          exit
        rescue Timeout::Error => e
          puts("Timeout error: please check the site you're benchmarking")
          exit          
        rescue SocketError => e
          puts e.message
          exit
        end

        response = case response
          when Net::HTTPSuccess
            response
          when Net::HTTPRedirection
            print "redirected to #{response['location']}\n"
            # we must correct the url, so we could select right inner links then
            # consider this: you request www.example.com and it redirects you to example.com
            # but the @url.host will be still www.example.com, so href.match(Regexp.escape(@url.host)) later will fail
            self.url = response['location']
            Net::HTTP.get_response(url)
          when Net::HTTPNotFound
            return []
        end

        doc = ::Nokogiri::HTML(response.body)
        links = select_local_links_from extract_links_from(doc), url
        local_links += links

        if max_depth > current_depth
          links.each do |link|
            local_links << fetch_links_from(URI.parse(link), max_depth, (current_depth + 1))
          end
        end
        
        puts "current_depth - #{current_depth}, local_links - #{local_links.inspect}" if @verbose

        local_links.reject{|l| l.empty?}.flatten.uniq
      end

      def prepare_queue
        @requests_queue = if @follow_links
          local_links = fetch_links_from(@url, @follow_links_depth)
          print "Found #{local_links.size} local links: #{local_links.inspect}\n"
          NethttpAb::RequestsQueue.new(local_links)
        else
          NethttpAb::SimpleRequestsQueue.new(@num_of_requests)         
        end
      end

      def start_threads
        @concurrent_users.times do
          #begin
          #  http_opened_session = get_http_session(@url)
          #rescue OpenSSL::SSL::SSLError => e
          #  puts "The url you provided is wrong, please check is it really ssl encrypted"
          #  exit
          #rescue Errno::ECONNREFUSED => e
          #  puts "Connection error, please check your internet connection or make sure the server is responding"
          #  exit
          #rescue SocketError => e
          #  puts e.message
          #  exit
          #end

          @threads << Thread.new do
            while !@requests_queue.empty? do
              # lock request in order to avoid sharing same request by two threads and making more requests then specified
              if next_url = @requests_queue.lock_next_request
                req = if @follow_links
                  next_url_parsed = URI.parse(next_url)
                  next_url_parsed.path = '/' if next_url_parsed.path == "" # ensure we requesting main page (if url is like http://google.com)
                  next_url_parsed
                else
                  @url
                end

                # TODO
                #req.add_field "User-Agent", "Mozilla/5.0 (X11; U; Linux i686; en-US) AppleWebKit/534.16 (KHTML, like Gecko) Chrome/10.0.648.204 Safari/534.16"

                @total_time += Benchmark.realtime do
                  begin
                    response = Net::HTTP.get_response(req) #http_opened_session.request(req)
                    response = case response
                      when Net::HTTPSuccess
                        response
                      when Net::HTTPRedirection
                        print "redirected to #{response['location']}\n"
                        Net::HTTP.get_response(URI.parse(response['location']))
                    end
                    
                    print '.' # show progress while processing queue

                    @mutex.synchronize do
                      @response_length += response.body.length
                      @successfull_requests += 1                      
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
                  ensure
                    @requests_queue.release_locked_request(next_url)
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
end
