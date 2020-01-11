# Author: Eugene Akhmetkhanov <axmetishe+github@gmail.com>
# Date: 07-01-2020
#
# Licensed to the Apache Software Foundation (ASF) under one
# or more contributor license agreements.  See the NOTICE file
# distributed with this work for additional information
# regarding copyright ownership.  The ASF licenses this file
# to you under the Apache License, Version 2.0 (the
# "License"); you may not use this file except in compliance
# with the License.  You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations
# under the License.

module Kitchen
  module Yansible
    module Tools
      module Files

        directories = [
          'host_vars',
          'roles',
          'modules',
          'spec',
          'library',
          'callback_plugins',
          'filter_plugins',
          'lookup_plugins',
          'ssh_private_keys',
        ]

        def host_inventory_file
          File.join(@config[:remote_executor] ? sandbox_path : instance_sandbox_roles, 'inventory.yml')
        end

        def playbook_file
          @config[:remote_executor] ? File.join( sandbox_path, @config[:playbook]) : @config[:playbook]
        end

        def generate_sandbox_path

        end
        def host_sandbox_root
          if !@host_sandbox_root && !instance.nil?
            @host_sandbox_root = File.join(config[:kitchen_root], %w[ .kitchen yansible ])
          end
          Dir.mkdir(@host_sandbox_root) unless File.exist?(@host_sandbox_root)
          @host_sandbox_root
        end

        def instance_sandbox_root
          if !@instance_sandbox_root && !instance.nil?
            @instance_sandbox_root = File.join(host_sandbox_root, @instance.name)
          end
          Dir.mkdir(@instance_sandbox_root) unless File.exist?(@instance_sandbox_root)
          @instance_sandbox_root
        end

        def instance_sandbox_roles
          if !@instance_sandbox_roles && !instance.nil?
            @instance_sandbox_roles = File.join(instance_sandbox_root, 'roles')
          end
          Dir.mkdir(@instance_sandbox_roles) unless File.exist?(@instance_sandbox_roles)
          @instance_sandbox_roles
        end

        def venv_root
          if !@venv_root && !instance.nil?
            @venv_root = File.join(@host_sandbox_root, 'venv')
          end
          @venv_root
        end

        def generate_inventory(inventory_file)
          connection = @instance.transport.instance_variable_get(:@connection_options)
          transport_conf = @instance.transport.diagnose

          host_conn_vars = {}
          host_conn_vars['ansible_connection'] = transport_conf[:name] if transport_conf[:name]
          host_conn_vars['ansible_password'] = connection[:password] if connection[:password]

          case transport_conf[:name]
          when 'winrm'
            host_conn_vars['ansible_host'] = URI.parse(connection[:endpoint]).hostname
            host_conn_vars['ansible_user'] = connection[:user] if connection[:user]
            host_conn_vars['ansible_winrm_transport'] = @config[:ansible_winrm_auth_transport] if @config[:ansible_winrm_auth_transport]
            host_conn_vars['ansible_winrm_scheme'] = transport_conf[:winrm_transport] == :ssl ? 'https' : 'http'
            host_conn_vars['ansible_winrm_server_cert_validation'] = @config[:ansible_winrm_cert_validation] if @config[:ansible_winrm_cert_validation]
          when 'ssh'
            host_conn_vars['ansible_host'] = connection[:hostname]
            host_conn_vars['ansible_user'] = connection[:username] if connection[:username]
            host_conn_vars['ansible_port'] = connection[:port] if connection[:port]
            host_conn_vars['ansible_ssh_retries'] = connection[:connection_retries] if connection[:connection_retries]
            host_conn_vars['ansible_private_key_file'] = connection[:keys].first if connection[:keys]
            host_conn_vars['ansible_host_key_checking'] = @config[:ansible_host_key_checking] if @config[:ansible_host_key_checking]
          else
            message = unindent(<<-MSG)
  
            ===============================================================================
             Unsupported transport - #{transport_conf[:name]}
             SSH and WinRM transports are allowed.
            ===============================================================================
            MSG
            raise UserError, message
          end

          inv = { 'all' => { 'hosts' => { @instance.name => host_conn_vars } } }

          File.open(inventory_file, 'w') do |file|
            file.write inv.to_yaml
          end
        end

        def copy_files(src,dst)
          info("Copy from '#{src}' to '#{dst}'")

          FileUtils.copy_entry(src, dst, remove_destination=true)
        end
      end
    end
  end
end
