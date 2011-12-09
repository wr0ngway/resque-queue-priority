# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require 'resque/plugins/queue_priority/version'


Gem::Specification.new do |s|
  s.name        = "resque-queue-priority"
  s.version     = Resque::Plugins::QueuePriority::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Matt Conway"]
  s.email       = ["matt@conwaysplace.com"]
  s.homepage    = "http://github.com/wr0ngway/resque-queue-priority"
  s.summary     = %q{A resque plugin for specifying the priority between queues that workers use to determine what to work on next}
  s.description = %q{A resque plugin for specifying the priority between queues that workers use to determine what to work on next}

  s.rubyforge_project = "resque-queue-priority"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_dependency("resque", '~> 1.10')
  s.add_development_dependency('rake')
  s.add_development_dependency('rspec', '~> 2.5')
  s.add_development_dependency('rack-test', '~> 0.5.4')

end

