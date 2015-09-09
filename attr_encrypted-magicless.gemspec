# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'attr_encrypted/version'

Gem::Specification.new do |s|
  s.name          = 'attr_encrypted-magicless'
  s.version       = AttrEncrypted::VERSION

  s.summary       = 'Encrypt and decrypt attributes'
  s.description   = 'Generates attr_accessors that encrypt and decrypt attributes transparently'

  s.authors       = ['Sean Huber', 'S. Brent Faulkner', 'William Monk', 'Stephen Aghaulor']
  s.email         = ['shuber@huberry.com', 'sbfaulkner@gmail.com', 'billy.monk@gmail.com', 'saghaulor@gmail.com']
  s.homepage      = 'https://github.com/estum/attr_encrypted'

  s.has_rdoc      = false
  s.rdoc_options  = ['--line-numbers', '--inline-source', '--main', 'README.rdoc']

  s.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features|\.travis\.yml|\.gitignore)/}) }
  s.bindir        = 'exe'
  s.executables   = s.files.grep(%r{^exe/}) { |f| File.basename(f) }
  s.require_paths = ['lib']
  s.test_files    = Dir['test/**/*']

  s.add_dependency 'encryptor', '>= 1.3.0'
  s.add_dependency 'activesupport', '>= 4.0', '< 5.0'

  s.add_development_dependency 'bundler', '~> 1.10'
  s.add_development_dependency 'rake', '~> 10.0'
  s.add_development_dependency 'sqlite3'
  s.add_development_dependency 'activerecord', '>= 4.0', '< 5.0'
  s.add_development_dependency 'minitest'
  s.add_development_dependency 'mocha', '~>1.0.0'
  s.add_development_dependency 'simplecov'
  s.add_development_dependency 'simplecov-rcov'
end
