# Blender-Chef

A [chef](https://www.chef.io/chef) based host discovery plugin for [Blender](https://github.com/PagerDuty/blender)

## Installation

```sh
  gem install blender-chef
```

## Usage
With blender-chef, host list for `blender` jobs can be automatically
fetched from Chef server. Following is an example of dynamically obtaining
all servers with `db` role, and enlisting their `iptables` rule.

```ruby
require 'blender/chef'
config(:chef, chef_sever_url: 'https://foo.bar.com', node_name: 'admin', client_key: 'admin.pem')
members(search(:chef, 'roles:db'))
ssh_task 'sudo iptables -L'
```
Aany valid chef search can be used. You can pass the `node_name`, `chef_server_url` and `client_key` for chef server config.
```ruby
config(:chef, node_name: 'admin', client_key: 'admin.pem', chef_server_url: 'https://example.com')
members(search(:chef, 'ec2_local_ipv4:10.13.12.11'))
ssh_task 'sudo iptables -L'
```
Alternatively, you can also use a config file lile `client.rb` or `knife.rb`
```ruby
config(:chef, config_file: '/etc/chef/client.rb')
members(search(:chef, 'roles:db'))
```

By default `blender-chef` will pass the FQDN of chef nodes as member list,
in this case as ssh targets. This can be customized by passing the attribute
option.

```ruby
config(:chef, node_name: 'admin', client_key: 'admin.pem')
members(search(:chef, 'roles:db', attribute: 'ec2_public_ipv4'))
```

### Knife integration

Blender-chef comes with a knife plugin that allows job or chef recipe
execution from CLI.

- Running raw blender jobs
  Given the following job present in file `jobs/upgrade_chef.rb`

  ```ruby
  ssh_task 'sudo apt-get remove chef --purge'
  ssh_task 'sudo apt-get remove chef --purge'
  ssh_task 'wget -c https://opscode-omnibus-packages.s3.amazonaws.com/ubuntu/13.04/x86_64/chef_12.0.3-1_amd64.deb'
  ssh_task 'sudo dpkg -i chef_12.0.3-1_amd64.deb'
  ssh_task 'sudo chef-client'
  ```

  It can be executed against all chef nodes having `db` role as:

  ```sh
  knife blend --search 'roles:db' jobs/upgrade_chef.rb
  ```
- Running local one-off chef recipes against remote nodes using blender
  Given the following chef recipe present ina local file `recipes/nginx.rb`

  ```ruby
  package 'nginx'
  service 'nginx' do
    action [:start, :enable]
  end
  ```

  It can be executed against all chef nodes having `web` role as:

  ```sh
  knife blend --recipe-mode --search 'roles:web' recipes/nginx.rb
  ```

  In `--recipe-mode` blender will treat the input file(s) as chef recipe
  and build necessary scp and ssh tasks to upload the recipe, execute it
  and remove the uploaded recipe.

  Additional options are provided to control strategy, ssh credentials etc.


## Supported ruby versions

Blender-chef uses Chef 12 (for partial search). For chef 11, use 0.0.1 version of blender-chef.

Blender-chef currently support the following MRI versions:

* *Ruby 1.9.3*
* *Ruby 2.1.0*
* *Ruby 2.1.2*

## License

[Apache 2](http://www.apache.org/licenses/LICENSE-2.0)

## Contributing

1. Fork it ( https://github.com/PagerDuty/blender-chef/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
```
