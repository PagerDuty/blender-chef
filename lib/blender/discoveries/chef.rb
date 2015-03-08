#
# Author:: Ranjib Dey (<ranjib@pagerduty.com>)
# Copyright:: Copyright (c) 2014 PagerDuty, Inc.
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require 'chef/search/query'

module Blender
  module Discovery
    class Chef
      attr_reader :options

      def initialize(options = {})
        @options = options
      end

      def search(opts = {})
        attr = options[:attribute] || 'fqdn'
        case opts
        when String
          search_term = opts
        when Hash
          search_term = opts[:search_term]
          attr = opts[:attribute] if opts.key?(:attribute)
        else
          raise ArgumentError, "Invalid argument type #{opts.class}"
        end
        search_term ||= '*:*'
        ::Chef::Config.from_file(options[:config_file]) if options[:config_file]
        ::Chef::Config[:node_name] = options[:node_name] if options[:node_name]
        ::Chef::Config[:client_key] = options[:client_key] if options[:client_key]
        ::Chef::Config[:chef_server_url] = options[:chef_server_url] if options[:chef_server_url]
        q = ::Chef::Search::Query.new
        res = q.search(:node, search_term, filter_result: {attribute: attr.split('.')})
        puts res.inspect
        res.first.collect{|node_data| node_data['data']['attribute']}
      end
    end
  end
end
