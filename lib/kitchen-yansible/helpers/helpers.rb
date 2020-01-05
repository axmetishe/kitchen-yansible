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

module Kitchen
  module Yansible
    module Helpers

      def unindent(s)
        s.gsub(/^#{s.scan(/^[ \t]+(?=\S)/).min}/, '')
      end

      def command_path(command)
        system("command -v #{command}")
      end

      def command_exists(command)
        "#{command_path("#{command} &>/dev/null")}"
      end

      def host_sandbox_root
        if !@local_sandbox_root && !instance.nil?
          @local_sandbox_root = File.join(
            config[:kitchen_root], %w{.kitchen venv}
          )
        end
        @local_sandbox_root
      end

      def execute_local_command(env, command)
        info("env=#{env} command=#{command}")
        _, stdout, stderr, wait_thr = Open3.popen3(env, command)
        Thread.new do
          stdout.each { |line| puts line }
        end
        exit_status = wait_thr.value

        message = unindent(<<-MSG)

          ===============================================================================
           Command returned '#{exit_status}'.
           stdout: '#{stdout.read}'
           stderr: '#{stderr.read}'
          ===============================================================================
        MSG
        raise UserError, message unless exit_status.success?
      end
    end
  end
end
