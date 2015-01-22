require 'spec_helper'
require 'blender/discoveries/chef'

describe Blender::Discovery::Chef do
  let(:discovery){described_class.new}
  it '#search' do
    expect(discovery.search.size).to be(10)
  end
  context '#against chef zero' do
    let(:disco) do
      described_class.new(
        chef_server_url: 'http://localhost:8889',
        node_name: 'admin',
        client_key: SpecHelper.client_key.path,
        attribute: 'name'
      )
    end
    it '#search without options' do
      expect(disco.search('name:node-1')).to eq(['node-1'])
    end
    it '#search with role based predicate' do
      expect(disco.search('roles:even')).to eq(["node-1", "node-3", "node-5", "node-7", "node-9"])
    end
    it '#search with attribute predicate' do
      expect(disco.search(search_term: 'roles:even', attribute: 'ipaddress').size).to eq(5)
    end
  end
end
