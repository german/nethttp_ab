# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{nethttp_ab}
  s.version = "0.0.5"

  s.required_rubygems_version = Gem::Requirement.new(">= 1.2") if s.respond_to? :required_rubygems_version=
  s.authors = ["Dmitrii Samoilov"]
  s.date = %q{2011-04-15}
  s.default_executable = %q{nethttp_ab}
  s.description = %q{Simple tool to test and benchmark sites}
  s.email = %q{germaninthetown@gmail.com}
  s.executables = ["nethttp_ab"]
  s.extra_rdoc_files = ["CHANGELOG", "LICENSE", "README", "bin/nethttp_ab", "lib/requester.rb", "lib/requests_queue.rb", "lib/simple_requests_queue.rb"]
  s.files = ["CHANGELOG", "Gemfile", "LICENSE", "Manifest", "README", "Rakefile", "bin/nethttp_ab", "lib/requester.rb", "lib/requests_queue.rb", "lib/simple_requests_queue.rb", "nethttp_ab.gemspec", "test/nethttp_ab_test.rb", "test/requests_queue_test.rb", "test/resources/index.html", "test/resources/links.html", "test/resources/links1.html", "test/resources/links2.html", "test/resources/links3.html", "test/resources/links4.html", "test/resources/links5.html", "test/simple_requests_queue_test.rb", "test/url_regexp_test.rb"]
  s.homepage = %q{http://github.com/german/nethttp_ab}
  s.rdoc_options = ["--line-numbers", "--inline-source", "--title", "Nethttp_ab", "--main", "README"]
  s.require_paths = ["lib"]
  s.licenses = ["MIT"]
  s.rubyforge_project = %q{nethttp_ab}
  s.rubygems_version = %q{1.6.2}
  s.summary = %q{Simple tool to test and benchmark sites}
  s.test_files = ["test/url_regexp_test.rb", "test/nethttp_ab_test.rb", "test/requests_queue_test.rb", "test/simple_requests_queue_test.rb"]

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<nokogiri>, [">= 1.4.2"])
    else
      s.add_dependency(%q<nokogiri>, [">= 1.4.2"])
    end
  else
    s.add_dependency(%q<nokogiri>, [">= 1.4.2"])
  end
end
