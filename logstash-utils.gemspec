# -*- encoding: utf-8 -*-
require File.expand_path('../lib/logstash-utils/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Greg Brockman"]
  gem.email         = ["gdb@gregbrockman.com"]
  gem.description   = "Logstash utlities"
  gem.summary       = "Various utilities for managing your logstash setup"
  gem.homepage      = ""

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "logstash-utils"
  gem.require_paths = ["lib"]
  gem.version       = Logstash::Utils::VERSION
end
