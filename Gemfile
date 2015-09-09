source 'https://rubygems.org'

ENV['ACTIVERECORD'] ||= '4.2'

gemspec

# support for testing with specific active record version
gem 'activerecord', "~> #{ENV['ACTIVERECORD']}" if ENV['ACTIVERECORD']
gem 'actionpack', "~> #{ENV['ACTIVERECORD']}" if ENV['ACTIVERECORD'] && ENV['ACTIVERECORD'] > '4.0'
