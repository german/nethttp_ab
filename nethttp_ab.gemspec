# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{nethttp_ab}
  s.version = "0.0.2"

  s.required_rubygems_version = Gem::Requirement.new(">= 1.2") if s.respond_to? :required_rubygems_version=
  s.authors = ["Dmitrii Samoilov"]
  s.date = %q{2011-04-06}
  s.default_executable = %q{nethttp_ab}
  s.description = %q{Simple tool to test and benchmark sites}
  s.email = %q{germaninthetown@gmail.com}
  s.executables = ["nethttp_ab"]
  s.extra_rdoc_files = ["CHANGELOG", "LICENSE", "README", "bin/nethttp_ab", "lib/net.rb", "lib/requester.rb", "lib/requests_queue.rb", "lib/simple_requests_queue.rb"]
  s.files = ["CHANGELOG", "LICENSE", "Manifest", "README", "Rakefile", "bin/nethttp_ab", "lib/net.rb", "lib/requester.rb", "lib/requests_queue.rb", "lib/simple_requests_queue.rb", "nethttp_ab.gemspec", "test/nethttp_ab_test.rb", "test/requests_queue_test.rb", "test/resources/index.html", "test/simple_requests_queue_test.rb"]
  s.homepage = %q{http://github.com/german/nethttp_ab}
  s.rdoc_options = ["--line-numbers", "--inline-source", "--title", "Nethttp_ab", "--main", "README"]
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{nethttp_ab}
  s.rubygems_version = %q{1.6.2}
  s.summary = %q{Simple tool to test and benchmark sites}
  s.test_files = ["test/nethttp_ab_test.rb", "test/requests_queue_test.rb", "test/simple_requests_queue_test.rb"]

  s.add_dependency('nokogiri', '>= 1.4.2')

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
    else
    end
  else
  end
end