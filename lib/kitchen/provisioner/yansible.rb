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
require 'kitchen-yansible/helpers/helpers'

module Kitchen
  module Provisioner
    class Yansible < Base
      include Kitchen::Yansible::Helpers

      kitchen_provisioner_api_version 2

      DEFAULT_CONFIG = {
        remote_executor: false,
        sandboxed_executor: false,
        ansible_binary: 'ansible-playbook',
        ansible_version: nil,
      }

      DEFAULT_CONFIG.each do |k, v|
        default_config k, v
      end

      def init_command
        info("Initializing #{name} driver")
        info("Working with '#{@instance.platform.os_type}' platform.")

        if @config[:remote_executor]
          if @instance.platform.os_type == 'windows'
            message = unindent(<<-MSG)
  
              ===============================================================================
               We can't use Windows platform with remote installation.
               Abandon ship!
              ===============================================================================
            MSG
            raise UserError, message
          end
          info('Using remote executor.')
          # execute remote
          # install via pip
          #
          ""
        else
          #   local executor
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

              if @instance.platform.os_type == 'windows'
                # ok, adding pywinrm
                info('==> Windows target platform may be tested only using local Ansible installation! <==')
                additional_packages.push('pywinrm')
              end

              # create sandbox
              if command_exists("#{host_sandbox_root}/bin/ansible")
                info("Ansible is installed at '#{host_sandbox_root}'.")
              else
                info("Ansible is not installed - will try to create local sandbox for execution")
                if command_exists('virtualenv')
                  system("virtualenv #{host_sandbox_root}")
                  system("#{host_sandbox_root}/bin/pip install " +
                    "ansible#{config[:ansible_version] ? "==#{config[:ansible_version]}" : ''}" +
                    " #{additional_packages.join(' ')}"
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

          ""
        end
      end

      def prepare_command
        info("Prepare command.")

        ""
      end

      def install_command
        info("Install command.")
        true_command
        # command_path(command)
      end

      def run_command
        info("Run command")
        ""
      end

      def command
        return @command if defined? @command
        @command = @config[:ansible_binary]
        debug("Ansible command: #{@command}")
        @command
      end
    end
  end
end
