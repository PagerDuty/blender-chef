require 'spec_helper'
require 'blender/discoveries/chef'

describe Blender::Discovery::Chef do
  let(:discovery){described_class.new}
  it '#search' do
    expect(discovery.search.size).to be(10)
  end
  it '#search with options' do
    disco = described_class.new(
      chef_server_url: 'http://localhost:8889',
      node_name: 'admin',
      client_key: SpecHelper.client_key.path,
      attribute: 'name'
    )
    expect(disco.search('name:node-1')).to eq(['node-1'])
  end
end
