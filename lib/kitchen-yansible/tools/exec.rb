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

require 'open3'

module Kitchen
  module Yansible
    module Tools
      module Exec
        def unindent(s)
          s.gsub(/^#{s.scan(/^[ \t]+(?=\S)/).min}/, '')
        end

        def check_command(command, args: '')
          "command -v #{command}" + "#{(" #{args}" if !args.empty?)}"
        end

        def command_exists(command)
          check_command(command, :args => '&>/dev/null')
        end

        def local_command_path(command, args: '')
          system(check_command(command, args))
        end

        def local_command_exists(command)
          "#{local_command_path(command, :args => '&>/dev/null')}"
        end

        def print_cmd_parameters(command, env = {})
          env_vars = []
          env.each { |k,v| env_vars.push("#{k}=#{v}") }
          message = unindent(<<-MSG)

            ===============================================================================
             Environment:
              #{env_vars.join("\n            ")}
             Command line:
              #{command}
            ===============================================================================
          MSG
          debug(message)
        end

        def print_cmd_error(stderr, proc)
          message = unindent(<<-MSG)

            ===============================================================================
             Command returned '#{proc.exitstatus}'.
             stderr: '#{stderr.read}'
            ===============================================================================
          MSG
          debug(message)
          raise UserError, message unless proc.success?
        end

        def execute_local_command(command, env: {}, opts: {}, print_stdout: false, return_stdout: false)
          print_cmd_parameters(command, env)

          Open3.popen3(env, command, opts) { |stdin, stdout, stderr, thread|
            if print_stdout
              while (line = stdout.gets)
                puts line
              end
            end
            proc = thread.value

            print_cmd_error(stderr, proc)
            return_stdout ? stdout.read : proc.success?
          }
        end

        # Helpers
        def sudo_env(pm)
          s = @config[:https_proxy] ? "https_proxy=#{@config[:https_proxy]}" : nil
          p = @config[:http_proxy] ? "http_proxy=#{@config[:http_proxy]}" : nil
          n = @config[:no_proxy] ? "no_proxy=#{@config[:no_proxy]}" : nil
          p || s ? "#{sudo('env')} #{p} #{s} #{n} #{pm}" : "#{sudo(pm)}"
        end

        # Taken from https://github.com/test-kitchen/test-kitchen/blob/master/lib/kitchen/provisioner/base.rb
        def sudo(script)
          "sudo -E #{script}"
        end
      end
    end
  end
end
