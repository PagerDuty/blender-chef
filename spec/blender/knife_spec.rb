require 'spec_helper'

require 'chef/knife/blender'
require 'blender/rspec'

describe Chef::Knife::Blend do
  before(:each) do
    Chef::Knife::Blend.load_deps
    @knife = Chef::Knife::Blend.new
    @knife.config[:user] = 'test-user'
    @knife.config[:passsword] = 'test-password'
    @knife.config[:search] = 'roles:db'
    @knife.config[:strategy] = :default
  end
  it '#non recipe mode' do
    @knife.name_args = ["job.rb"]
    stub_search(:chef, 'roles:db').and_return(%w(host1 host2))
    expect(File).to receive(:read).with('job.rb').and_return('')
    @knife.config[:mode] = :blender
    @knife.run
  end
  it '#recipe mode' do
    @knife.name_args = ["job.rb"]
    @knife.config[:mode] = :recipe
    stub_search(:chef, 'roles:db').and_return([])
    @knife.run
  end
  it '#berkshelf mode' do
    @knife.name_args = ['/path/to/berksfile']
    @knife.config[:mode] = :recipe
    stub_search(:chef, 'roles:db').and_return([])
    @knife.run
  end
end
