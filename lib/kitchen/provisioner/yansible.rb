# Author: Eugene Akhmetkhanov <axmetishe+github@gmail.com>
# Date: 03-01-2020
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

require 'kitchen'
require 'kitchen/errors'
require 'kitchen/provisioner/base'
require 'kitchen-yansible/tools/install'
require 'kitchen-yansible/tools/files'
require 'kitchen-yansible/tools/exec'
require 'kitchen-yansible/tools/dependencies'

module Kitchen
  module Provisioner
    class Yansible < Base
      include Kitchen::Yansible::Tools
      include Kitchen::Yansible::Tools::Exec
      include Kitchen::Yansible::Tools::Files
      include Kitchen::Yansible::Tools::Dependencies

      kitchen_provisioner_api_version 2

      DEFAULT_CONFIG = {
        remote_executor: false,
        remote_install_path: '/tmp/ansible',
        sandboxed_executor: false,
        playbook: 'default.yml',
        ansible_binary: 'ansible-playbook',
        ansible_version: nil,
        ansible_config: nil,
        ansible_extra_arguments: nil,
        ansible_force_color: true,
        ansible_host_key_checking: false,
        ansible_winrm_auth_transport: nil,
        ansible_winrm_cert_validation: 'ignore',
        ansible_verbose: false,
        ansible_verbosity: 1,
        ansible_roles_path: 'roles',
        dependencies: [],
      }

      # noinspection RubyYardParamTypeMatch
      DEFAULT_CONFIG.each { |k, v| default_config k, v }

      def install_command
        info("Installing provisioner software.")
        info("Working with '#{@instance.platform.os_type}' platform.")
        debug("Driver info: '#{@instance.driver.diagnose}'.")
        debug("Transport info: '#{@instance.transport.diagnose}'.")
        debug("Platform info: '#{@instance.platform.diagnose}'.")
        instance_platform = detect_platform

        if @config[:remote_executor]
          if windows_os?
            message = unindent(<<-MSG)

              ===============================================================================
               We can't use Windows platform with remote installation.
               Abandon ship!
              ===============================================================================
            MSG
            raise UserError, message
          end
          info('Using remote executor.')

          """
            #{Install.make(@config, instance_platform).remote_install}
          """
        else
          info('Using local executor.')
          if command_exists(command) and !@config[:sandboxed_executor]
            info('Ansible is installed already - proceeding further steps.')
          else
            if RbConfig::CONFIG["host_os"] =~ /mswin|mingw/
              message = unindent(<<-MSG)

                ===============================================================================
                 We can't use Windows platform as a Host system for sandboxing.
                 Abandon ship!
                ===============================================================================
              MSG
              raise UserError, message
            else
              additional_packages = []
              info('Checking for sandboxed Ansible version.')

              if windows_os?
                # ok, adding pywinrm
                info('==> Windows target platform may be tested only using local Ansible installation! <==')
                additional_packages.push('pywinrm')
              end

              # create sandbox
              if command_exists("#{venv_root}/bin/ansible")
                info("Ansible is installed at '#{venv_root}'.")
              else
                info("Ansible is not installed - will try to create local sandbox for execution")
                if command_exists('virtualenv')
                  system("virtualenv #{venv_root}")
                  system("#{venv_root}/bin/pip install " +
                           "#{Install.make(@config, instance_platform).pip_required_packages.join(' ')}"
                  )
                else
                  message = unindent(<<-MSG)

                    ===============================================================================
                     Couldn't find virtualenv binary for sandboxing.
                     Please make sure execution host has Python and VirtualEnv packages installed.
                    ===============================================================================
                  MSG
                  raise UserError, message
                end
              end
            end
          end

          """
            #{Install.make(@config, instance_platform).local_install}
          """
        end
      end

      def init_command
        info("Initializing provisioner software.")
        "mkdir #{windows_os? ? '-Force' : '-p'} #{config[:root_path]}"
      end

      def prepare_command
        info("Preparing configuration for provisioner.")
        unless @config[:remote_executor]
          generate_inventory(inventory_file)
        end

        ""
      end

      def create_sandbox
        super

        directories = %w[
          roles
          host_vars
          group_vars
          module_utils
          library
          callback_plugins
          connection_plugins
          filter_plugins
          lookup_plugins
        ]

        prepare_dependencies(@config[:dependencies])
        generate_inventory(inventory_file, remote: true)

        info("Copy dependencies to sandbox")
        copy_dirs_to_sandbox(dependencies_tmp_dir, dst: 'roles')
        directories.each do |directory|
          if File.directory?(directory)
            info("Copy #{directory} to sandbox")
            copy_dirs_to_sandbox(directory)
          end
        end
        info("Prepare config")
        prepare_ansible_config
        info("Prepare playbook")
        prepare_playbook_file
        info("Prepare inventory file")
        prepare_inventory_file
      end

      def run_command
        if @config[:remote_executor]
          info("Execute Ansible remotely.")

          command_env_script = []
          if %w(darwin mac macos macosx).include? detect_platform
            command_env_script.push('source ~/.profile')
          end

          command_env.each {|k,v| command_env_script.push(shell_env_var(k, v))}

          """
            #{command_env_script.join('; ')}; #{command} #{command_args.join(' ')}
          """
        else
          info("Execute Ansible locally.")
          execute_local_command("#{command} #{command_args.join(' ')}", env: command_env, print_stdout: true)

          ""
        end
      end

      def command
        return @command if defined? @command

        @command = @config[:ansible_binary]
        debug("Ansible command: #{@command}")
        @command
      end

      def command_env
        return @command_env if defined? @command_env

        # noinspection RubyStringKeysInHashInspection
        @command_env = {
          'ANSIBLE_FORCE_COLOR' => @config[:ansible_force_color].to_s,
          'ANSIBLE_HOST_KEY_CHECKING' => @config[:ansible_host_key_checking].to_s,
          'ANSIBLE_INVENTORY_ENABLED' => 'yaml',
          'ANSIBLE_RETRY_FILES_ENABLED' => false.to_s,
          'ANSIBLE_ROLES_PATH' => remote_file_path('roles', fallback: generate_sandbox_path('roles')),
        }
        @command_env['ANSIBLE_CONFIG'] = @config[:ansible_config] if @config[:ansible_config]

        @command_env
      end

      def command_args
        return @command_args if defined? @command_args

        @command_args = []
        @config[:ansible_extra_arguments].each { |arg| @command_args.push(arg) } if @config[:ansible_extra_arguments]
        @config[:ansible_verbose] ? @command_args.push('-' + 'v' * @config[:ansible_verbosity]) : ''
        @command_args.push("--inventory='#{remote_file_path(ANSIBLE_INVENTORY, fallback: inventory_file)}'")
        @command_args.push("--limit='#{@instance.name}'")
        @command_args.push(remote_file_path(@config[:playbook]))

        @command_args
      end
    end
  end
end
