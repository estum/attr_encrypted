if RUBY_VERSION >= '1.9.3'
  require 'simplecov'
  require 'simplecov-rcov'

  SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter[
    SimpleCov::Formatter::HTMLFormatter,
    SimpleCov::Formatter::RcovFormatter,
  ]

  SimpleCov.start do
    add_filter 'test'
  end
end

# ENV['ACTIVE_RECORD_VERSION'] ||= ENV['ACTIVERECORD']

require 'minitest'
require 'minitest/autorun'
require 'digest/sha2'
require 'rubygems'
gem 'activerecord', ENV['ACTIVE_RECORD_VERSION'] if ENV['ACTIVE_RECORD_VERSION']
require 'active_record'
require 'mocha/test_unit'

$:.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$:.unshift(File.dirname(__FILE__))
require 'attr_encrypted'

require 'active_support/lazy_load_hooks'

ActiveSupport.on_load(:active_record) do
  include AttrEncrypted
end

puts "\nTesting with ActiveRecord #{ActiveRecord::VERSION::STRING rescue ENV['ACTIVE_RECORD_VERSION']}"

SECRET_KEY = 4.times.map { Digest::SHA256.hexdigest((Time.now.to_i * rand(5)).to_s) }.join

