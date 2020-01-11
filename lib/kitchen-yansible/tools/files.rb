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
        ANSIBLE_INVENTORY = "inventory.yml"

        def inventory_file
          File.join(instance_tmp_dir, ANSIBLE_INVENTORY)
        end

        def remote_file_path(file_path, fallback: nil)
          if @config[:remote_executor]
            File.join(@config[:root_path], file_path)
          else
            fallback.nil? ? file_path : fallback
          end
        end

        def prepare_playbook_file
          if @config[:remote_executor]
            copy_files(@config[:playbook], File.join(sandbox_path, @config[:playbook]))
          end
        end

        def prepare_inventory_file
          if @config[:remote_executor]
            copy_files(inventory_file, File.join(sandbox_path, ANSIBLE_INVENTORY))
          end
        end

        def generate_sandbox_path(directory)
          path = File.join(sandbox_path, directory)
          Dir.mkdir(path) unless File.exist?(path)
          path
        end

        def executor_tmp_dir
          if !@executor_tmp_dir && !instance.nil?
            @executor_tmp_dir = File.join(config[:kitchen_root], %w[ .kitchen yansible ])
          end
          Dir.mkdir(@executor_tmp_dir) unless File.exist?(@executor_tmp_dir)
          @executor_tmp_dir
        end

        def instance_tmp_dir
          if !@instance_tmp_dir && !instance.nil?
            @instance_tmp_dir = File.join(executor_tmp_dir, @instance.name)
          end
          Dir.mkdir(@instance_tmp_dir) unless File.exist?(@instance_tmp_dir)
          @instance_tmp_dir
        end

        def dependencies_tmp_dir
          if !@dependencies_tmp_dir && !instance.nil?
            @dependencies_tmp_dir = File.join(instance_tmp_dir, 'dependencies')
          end
          Dir.mkdir(@dependencies_tmp_dir) unless File.exist?(@dependencies_tmp_dir)
          @dependencies_tmp_dir
        end

        def venv_root
          if !@venv_root && !instance.nil?
            @venv_root = File.join(@host_sandbox_root, 'venv')
          end
          @venv_root
        end

        def generate_inventory(inventory_file, remote: false)
          connection = @instance.transport.instance_variable_get(:@connection_options)
          transport_conf = @instance.transport.diagnose
          host_conn_vars = {}

          debug("===> Connection options")
          debug(connection.to_s)
          debug("===> Transport options")
          debug(transport_conf.to_s)
          if remote
            debug("Generating inventory stub for execution on remote target")
            host_conn_vars['ansible_connection'] = 'local'
            host_conn_vars['ansible_host'] = 'localhost'
          else
            debug("Generating inventory for execution on local host with remote targets")
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
          end

          # noinspection RubyStringKeysInHashInspection
          inv = { 'all' => { 'hosts' => { @instance.name => host_conn_vars } } }

          File.open(inventory_file, 'w') do |file|
            file.write inv.to_yaml
          end
        end

        def copy_files(src, dst, overwrite: true)
          debug("Copy '#{src}' to '#{dst}'")

          FileUtils.copy_entry(src, dst, remove_destination=overwrite)
        end

        def copy_dirs(src, dst, reject: '.git')
          expand_path=File.expand_path(src)
          debug("Copy '#{src}' to '#{dst}'.")
          debug("'#{src}' expanded to '#{expand_path}'")
          Dir.glob("#{expand_path}/**/{*,.*}").reject{|f| f[reject]}.each do |file|
            target = dst + file.sub(expand_path, '')
            File.file?(file) ? FileUtils.copy(file, target) : FileUtils.mkdir(target) unless File.exist?(target)
          end
        end

        def copy_dirs_to_sandbox(src, dst: src, reject: '.git')
          dest = generate_sandbox_path(dst)
          debug("'#{src}' => '#{dest}', reject => '#{reject}'.")

          copy_dirs(src, dest, reject: reject)
        end
      end
    end
  end
end
