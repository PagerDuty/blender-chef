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

      option :prompt,
        default: false,
        boolean: true,
        long: '--prompt',
        description: 'Prompt for password'

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

      desc = "Run mode. Can be 'blender', 'recipe' or 'berkshelf'\n"
      desc << "In 'blender' mode input file is treated as a Blender job\n"
      desc << "In 'recipe' mode input file is treated as an individual recipe and executed using chef-apply\n"
      desc << "In 'berkshelf' mode input file is treated as a Berksfile. Blender vendors cookbook using berksshelf, scp it and run chef against it in localmode\n"
      option :mode,
        long: '--mode MODE',
        short: '-m MODE',
        description: desc,
        default: :blender,
        proc: lambda{|s| s.to_sym}

      option :chef_apply,
        long: '--chef-apply',
        short: '-A',
        description: 'chef-apply command to be used (effective only in recipe mode)',
        default: 'chef-apply'

      option :run_list,
        long: '--run-list RUN_LIST',
        short: '-r RUN_LIST',
        description: 'chef-apply command to be used (effective only in berkshelf mode)'

      option :hosts,
        long: '--hosts HOST1,HOST2,HOST3',
        short: '-h HOST1,HOST2,HOST3',
        description: 'Pass hosts manually (search and attribute option will be ignored)'

      def run
        scheduler_options = {
          config_file: config[:blender_config],
          no_doc: config[:quiet]
        }

        discovery_options = {
          attribute: config[:attribute]
        }

        Blender::Configuration[:noop] = config[:noop]

        if config[:hosts]
          members = config[:hosts].split(',')
        else
          members = Blender::Discovery::Chef.new(discovery_options).search(config[:search])
        end
        ssh_config = ssh_options
        Blender.blend('blender-chef', scheduler_options) do |scheduler|
          scheduler.strategy(config[:strategy])
          scheduler.config(:ssh, ssh_config)
          scheduler.config(:ssh_multi, ssh_config)
          scheduler.config(:scp, ssh_config)
          scheduler.members(members)
          @name_args.each do |file|
            case config[:mode]
            when :berkshelf
              begin
                require 'berkshelf'
              rescue LoadError
                raise RuntimeError, 'You must install berkshelf before using blender-chef in berkshelf mode'
              end
              tempdir = Dir.mktmpdir
              berkshelf_mode(scheduler, tempdir, file)
              FileUtils.rm_rf(tempdir)
            when :recipe
              recipe_mode(scheduler, file)
            when :blender
              blender_mode(scheduler, file)
            else
              raise ArgumentError, "Unknown mode: '#{config[:mode]}'"
            end
          end
        end
      end

      def ssh_options
        opts = {
          user: config[:user]
        }
        if config[:identity_file]
          opts[:keys] = Array(config[:identity_file])
        end
        if config[:stream] or (!config[:quiet])
          opts[:stdout] = $stdout
        end
        if config[:password]
          opts[:password] = config[:password]
        elsif config[:prompt]
          opts[:password] = ui.ask('SSH password: ') {|q|q.echo = false}
        end
        opts
      end

      def berkshelf_mode(scheduler, tempdir, file)
        run_list = config[:run_list]
        scheduler.ruby_task 'generate cookbook tarball' do
          execute do
            berksfile = Berkshelf::Berksfile.from_file('Berksfile')
            berksfile.vendor(tempdir)
            File.open('/tmp/solo.rb', 'w') do |f|
              f.write("cookbook_path '/tmp/cookbooks'\n")
              f.write("file_cache_path '/var/cache/chef/cookbooks'\n")
            end
          end
        end
        scheduler.ssh_task 'nuke old cookbook directory if exist' do
          execute 'rm -rf /tmp/cookbooks'
        end
        scheduler.scp_upload 'upload cookbooks' do
          from tempdir
          to '/tmp/cookbooks'
          recursive true
        end
        scheduler.scp_upload '/tmp/solo.rb' do
          from '/tmp/solo.rb'
        end
        scheduler.ssh_task 'create cache directory' do
          execute 'sudo mkdir -p /var/cache/chef/cookbooks'
        end
        scheduler.ssh_task 'run chef solo' do
          execute "sudo chef-client -z -o #{run_list} -c /tmp/solo.rb --force-logger"
        end
      end

      def recipe_mode(scheduler, file)
        remote_path = File.join('/tmp', SecureRandom.hex(10))
        scheduler.scp_upload('upload recipe') do
          to remote_path
          from file
        end
        scheduler.ssh_task "#{config[:chef_apply]} #{remote_path}"
        scheduler.ssh_task "rm #{remote_path}"
      end

      def blender_mode(scheduler, file)
        job = File.read(file)
        scheduler.instance_eval(job, __FILE__, __LINE__)
      end
    end
  end
end
