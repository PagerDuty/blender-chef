require 'spec_helper'

require 'chef/knife/blender'

describe Chef::Knife::Blend do
  before(:each) do
    Chef::Knife::Blend.load_deps
    @knife = Chef::Knife::Blend.new
    @knife.config[:user] = 'test-user'
    @knife.config[:passsword] = 'test-password'
    @knife.config[:search] = 'roles:db'
    @knife.config[:strategy] = :default
    @knife.name_args = ["job.rb"]
  end
  it '#non recipe mode' do
    disco = double(Blender::Discovery::Chef)
    expect(Blender::Discovery::Chef).to receive(:new).and_return(disco)
    expect(disco).to receive(:search).and_return(['host1', 'host2'])
    expect(File).to receive(:read).with('job.rb').and_return('')
    @knife.run
  end
  it '#recipe mode' do
    @knife.config[:recipe_mode] = true
    disco = double(Blender::Discovery::Chef)
    expect(Blender::Discovery::Chef).to receive(:new).and_return(disco)
    expect(disco).to receive(:search).and_return([])
    @knife.run
  end
end
