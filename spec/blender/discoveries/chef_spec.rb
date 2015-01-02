require 'spec_helper'
require 'blender/discoveries/chef'

describe Blender::Discovery::Chef do
  let(:discovery){described_class.new}
  it '#search' do
    query = double(Chef::Search::Query)
    expect(query).to receive(:search).with(
      :node,
      '*:*',
      filter_result: {
        attribute: ['fqdn']
      }
    ).and_return([['data'=> { 'attribute'=> 'a'}]])
    expect(Chef::Search::Query).to receive(:new).and_return(query)
    expect(discovery.search).to eq(['a'])
  end
  it '#search with options' do
    disco = described_class.new(
      config_file: 'foo.rb',
      node_name: 'bar',
      client_key: 'baz.rb',
      attribute: 'x.y.z'
    )
    query = double(Chef::Search::Query)
    expect(Chef::Config).to receive(:from_file).with('foo.rb')
    expect(query).to receive(:search).with(
      :node,
      'name:x',
      filter_result: {
        attribute: %w{x y z}
      }
    ).and_return([[{'data'=>{'attribute'=> 123}}]])
    expect(Chef::Search::Query).to receive(:new).and_return(query)
    expect(disco.search('name:x')).to eq([123])
    expect(Chef::Config[:client_key]).to eq('baz.rb')
    expect(Chef::Config[:node_name]).to eq('bar')
  end
end
