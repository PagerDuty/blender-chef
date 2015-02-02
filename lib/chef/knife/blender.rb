#
# Author:: Ranjib Dey (<ranjib@pagerduty.com>)
# Copyright:: Copyright (c) 2015 PagerDuty, Inc.
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
#

require 'chef/knife'

class Chef
  class Knife
    class Blend < Chef::Knife

      banner 'knife blend FILE (options)'

      deps do
        require 'blender'
        require 'blender/chef'
      end

      option :search,
        short: '-s SEARCH_TERM',
        long: '--search SEARCH_TERM',
        description: 'Chef search query',
        default: '*:*'

      option :attribute,
        short: '-a ATTRIBUTE',
        long: '--attribute ATTRIBUTE',
        description: 'Node attribute that will used as SSH hostname',
        default: 'fqdn'

      option :blender_config,
        default: nil,
        long: :'--blender-config CONFIG_FILE',
        description: 'Provide blender configuration via json file'

      option :noop,
        default: false,
        boolean: true,
        short: '-n',
        long: '--noop',
        description: 'no-op aka dry-run mode, run blender without executing jobs'

      option :quiet,
        default: false,
        boolean: true,
        short: '-q',
        description: 'Quiet mode. Disable printing running job details'

      option :user,
        default: ENV['USER'],
        short: '-u USER',
        long: '--user USER',
        description: 'SSH User'

      option :password,
        short: '-p PASSWORD',
        long: '--password PASSWORD',
        description: 'SSH password'

      option :quiet,
        default: false,
        boolean: true,
        short: '-q',
        description: 'Quiet mode. Disable printing running job details'

      option :stream,
        default: true,
        boolean: true,
        long: '--stream',
        description: 'Stream STDOUT of commands(works only if quiet mode is not used)'

      option :strategy,
        default: :default,
        long: '--strategy STRATEGY',
        description: 'Strategy of execution (default, per_host or per_task)',
        proc: lambda{|strategy| strategy.to_sym}

      option :identity_file,
        short: '-i IDENTITY_FILE',
        long: '--identity-file IDENTITY_FILE',
        description: 'Identity file for SSH authentication'

      option :recipe_mode,
        long: '--recipe-mode',
        description: 'Treat input files as chef recipe and compose blender tasks to execute them (scp + ssh)',
        boolean: true,
        default: false

      option :recipe_mode,
        long: '--recipe-mode',
        description: 'Treat input files as chef recipe and compose blender tasks to execute them (scp + ssh)',
        boolean: true,
        default: false

      option :chef_apply,
        long: '--chef-apply',
        short: '-A',
        description: 'chef-apply command to be used (effective only in recipe mode)',
        default: 'chef-apply'

      def run
        ssh_options = {
          user: config[:user],
          stdout: $stdout
        }
        ssh_options[:stdout] = $stdout if config[:stream]
        if config[:password]
          ssh_options[:password] = config[:password]
        elsif config[:prompt]
          ssh_options[:password] = ui.ask('SSH password: ') {|q|q.echo = false}
        end
        if config[:identity_file]
          ssh_options[:keys] = Array(config[:identity_file])
        end
        scheduler_options = {
          config_file: config[:blender_config],
          no_doc: config[:quiet]
        }
        discovery_options = {
          attribute: config[:attribute]
        }
        Blender::Configuration[:noop] = config[:noop]
        members = Blender::Discovery::Chef.new(discovery_options).search(config[:search])

        @name_args.each do |file|
          if config[:recipe_mode]
            remote_path = File.join('/tmp', SecureRandom.hex(10))
            Blender.blend(options[:file], scheduler_options) do |scheduler|
              scheduler.strategy(config[:strategy])
              scheduler.config(:ssh, ssh_options)
              scheduler.config(:scp, ssh_options)
              scheduler.members(members)
              scheduler.scp_upload(remote_path) do
                from file
              end
              scheduler.ssh_task "#{config[:chef_apply]} #{remote_path}"
              scheduler.ssh_task "rm #{remote_path}"
            end
          else
            job = File.read(file)
            Blender.blend(options[:file], scheduler_options) do |scheduler|
              scheduler.strategy(config[:strategy])
              scheduler.config(:ssh, ssh_options)
              scheduler.members(members)
              scheduler.instance_eval(job, __FILE__, __LINE__)
            end
          end
        end
      end
    end
  end
end
