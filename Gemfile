source 'https://rubygems.org'

# gem 'encryptor', git: 'https://github.com/attr-encrypted/encryptor'

ENV['ACTIVERECORD'] ||= '4.2'

gemspec

# Lock to "rake" version 0.9.2.2 in order to use deprecated "rake/rdoctask".
# Once we drop official support for Ruby 1.8.7, we can loosen this constraint
# and allow our dependencies to "float" to the latest version of "rake".
gem 'rake', '0.9.2.2'

# support for testing with specific active record version
gem 'activerecord', "~> #{ENV['ACTIVERECORD']}" if ENV['ACTIVERECORD']
gem 'actionpack', "~> #{ENV['ACTIVERECORD']}" if ENV['ACTIVERECORD'] && ENV['ACTIVERECORD'] > '4.0'
