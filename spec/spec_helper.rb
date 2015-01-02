require 'blender'
require 'chef_zero/server'
require 'fileutils'
require 'chef/node'
require 'tempfile'
require 'fauxhai'

module SpecHelper
  extend self
  def server
    $server ||= ChefZero::Server.new
  end
  def client_key
    $client_key ||= Tempfile.new('client.pem')
  end
  def setup
    server.start_background
    Chef::Config[:chef_server_url] = 'http://127.0.0.1:8889'
    Chef::Config[:node_name] = 'admin'
    Chef::Config[:client_key] = client_key.path
    client_key.write(server.gen_key_pair.first)
    client_key.close
    10.times do |n|
      node = Chef::Node.new
      node.name('node-'+ (n+1).to_s)
      node.consume_attributes(
        Fauxhai.mock(platform: 'ubuntu', version: '14.04').data
      )
      node.save
    end
  end
  def cleanse
    client_key.unlink
    server.stop
  end
end

RSpec.configure do |config|
  config.mock_with :rspec do |mocks|
    mocks.verify_doubled_constant_names = true
  end
  config.before(:suite) do
    SpecHelper.setup
  end
  config.after(:suite) do
    SpecHelper.cleanse
  end
  config.backtrace_exclusion_patterns = []
end
