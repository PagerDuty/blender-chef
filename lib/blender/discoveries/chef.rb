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

      def search(search_term = '*:*')
        if options[:config_file]
          ::Chef::Config.from_file options[:config_file]
        end
        if options[:node_name]
          ::Chef::Config[:node_name] = options[:node_name]
        end
        if options[:client_key]
          ::Chef::Config[:client_key] = options[:client_key]
        end
        if options[:chef_server_url]
          ::Chef::Config[:chef_server_url] = options[:chef_server_url]
        end
        attr = options[:attribute] || 'fqdn'
        q = ::Chef::Search::Query.new
        res = q.search(:node, search_term, filter_result: {attribute: attr.split('.')})
        res.first.collect{|node_data| node_data['data']['attribute']}
      end
    end
  end
end
