require 'test/unit'

require File.dirname(File.expand_path(__FILE__)) + '/../lib/requester.rb'

class UrlRegexpTest < Test::Unit::TestCase
  def setup
    @fail_urls = %w{www./yandex.ru yandex.123ru germaninthetown@gmail.com abcde index.html}

    @correct_urls = %w{www.google.com google.com http://google.com http://mail.ya.ru mail.ya.ru/ mail.ya.ru/test http://www.my-site.org/articles/2011/04/12/123-nethttpab-is-great}
  end

  def test_url_regexp
    @correct_urls.each do |correct_url|
      assert(correct_url =~ NethttpAb::Requester::URL_REGEXP)
    end

    @fail_urls.each do |fail_url|
      assert(fail_url !~ NethttpAb::Requester::URL_REGEXP)
    end
  end
end
