#!/usr/bin/env ruby
require 'rubygems'
require 'trollop'
require File.dirname(File.expand_path(__FILE__)) + '/lib/requester.rb'

# USAGE:
# ./nethttp_ab.rb -n 100 -c 3 http://www.yoursite.com
# OR 
# ./nethttp_ab.rb --follow_links http://localhost:3000

opts = Trollop::options do
  opt :concurrent_threads, "Number of concurrent threads", :default => 3, :short => 'c'
  opt :requests, "Total number of requests", :default => 10, :short => 'n'
  opt :follow_links, "Whether to follow links from received pages (emulating real user)", :default => false, :short => 'f'  
end

url_to_benchmark = "http://localhost:3000/"
# search for the url to perform benchmarking on
# we don't use trollop here since I don't like to specify --url=http://mysite.com to get the url
ARGV.each do |arg|
  url_to_benchmark = arg if arg =~ /https?:\/\/|www\./
end

requester = Requester.new
requester.concurrent_users  = opts[:concurrent_threads]
requester.num_of_requests   = opts[:requests]
requester.follow_links      = opts[:follow_links]
requester.url               = url_to_benchmark

requester.proceed
requester.print_stats
