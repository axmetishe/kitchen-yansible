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

require 'kitchen-yansible/tools/exec'
require 'kitchen-yansible/tools/install/rhel'
require 'kitchen-yansible/tools/install/fedora'
require 'kitchen-yansible/tools/install/amazon'
require 'kitchen-yansible/tools/install/debian'
require 'kitchen-yansible/tools/install/windows'

module Kitchen
  module Yansible
    module Tools
      class Install
        include Kitchen::Yansible::Tools::Exec

        BINARY_INSTALL_PREFIX='/usr/local/bin'
        BINARY_DEFAULT_PREFIX='/usr/bin'

        def python_version_size
          1
        end

        def initialize(config, platform)
          @config = config
          @platform = platform
        end

        def self.make(config, platform)
          return nil if platform == ''

          case platform.downcase
          when /^(debian|ubuntu).*/
            return Debian.new(config, platform)
          when /^(redhat|centos|oracle).*/
            return RHEL.new(config, platform)
          when /^fedora.*/
            return Fedora.new(config, platform)
          when /^amazon.*/
            return Amazon.new(config, platform)
          # when 'suse', 'opensuse', 'sles'
          #   return Suse.new(platform, config)
          # when 'darwin', 'mac', 'macos', 'macosx'
          #   return Darwin.new(platform, config)
          # when 'alpine'
          #   return Alpine.new(platform, config)
          # when 'openbsd'
          #   return Openbsd.new(platform, config)
          # when 'freebsd'
          #   return Freebsd.new(platform, config)
          when /^windows.*/
            return Windows.new(config, platform)
          else
            raise UserError "Unsupported platform - '#{platform.to_s}'!"
          end
        end

        def remote_install
          """
            #{preinstall_command}
            #{search_alternatives}
            #{install_python}
            #{install_virtualenv}
            #{install_ansible_pip('/tmp/ansible')}

            preInstall
            installPython
            installVirtualenv
            #{command_exists('ansible')} && {
              ansible --version|head -n1|grep -i 'ansible #{ansible_version}' &>/dev/null || installAnsiblePip
            } || installAnsiblePip
          """
        end

        def local_install
          """
            #{preinstall_command}
            #{search_alternatives}
            #{install_python}

            preInstall
            installPython
          """
        end

        def ansible_version
          (@config[:ansible_version] && @config[:ansible_version] != 'latest') ? @config[:ansible_version].to_s : ''
        end

        def pip_version(version)
          version.empty? ? '' : "==#{version}"
        end

        def pip_required_packages
          [
            "ansible#{pip_version(ansible_version)}",
          ]
        end

        def get_python_version
          "python -c 'import sys; print(\"\".join(map(str, sys.version_info[:#{python_version_size}])))'"
        end

        def package_manager
          "#{sudo_env('yum')}"
        end

        def update_cache
          "#{package_manager} makecache"
        end

        def install_package
          "#{package_manager} install -y"
        end

        def install_ansible_pip(sandbox_path)
          """
            installAnsiblePip () {
              echo \"Installing Ansible via Pip\"

              virtualenv #{sandbox_path}/venv
              #{sandbox_path}/venv/bin/pip install $PIP_ARGS --upgrade pip setuptools
              #{sandbox_path}/venv/bin/pip install $PIP_ARGS #{pip_required_packages.join(' ')}
              #{ansible_alternatives(BINARY_INSTALL_PREFIX, sandbox_path)}
            }
          """
        end

        def alternatives_command
          "#{sudo('alternatives')}"
        end

        def ansible_alternatives(install_prefix, sandbox_path)
          """
            #{command_exists("#{sandbox_path}/venv/bin/ansible")} && {
              #{alternatives_command} --install #{install_prefix}/ansible ansible #{sandbox_path}/venv/bin/ansible 100 \\
                --slave #{install_prefix}/ansible-config ansible-config #{sandbox_path}/venv/bin/ansible-config \\
                --slave #{install_prefix}/ansible-connection ansible-connection #{sandbox_path}/venv/bin/ansible-connection \\
                --slave #{install_prefix}/ansible-console ansible-console #{sandbox_path}/venv/bin/ansible-console \\
                --slave #{install_prefix}/ansible-doc ansible-doc #{sandbox_path}/venv/bin/ansible-doc \\
                --slave #{install_prefix}/ansible-galaxy ansible-galaxy #{sandbox_path}/venv/bin/ansible-galaxy \\
                --slave #{install_prefix}/ansible-inventory ansible-inventory #{sandbox_path}/venv/bin/ansible-inventory \\
                --slave #{install_prefix}/ansible-playbook ansible-playbook #{sandbox_path}/venv/bin/ansible-playbook \\
                --slave #{install_prefix}/ansible-pull ansible-pull #{sandbox_path}/venv/bin/ansible-pull \\
                --slave #{install_prefix}/ansible-test ansible-test #{sandbox_path}/venv/bin/ansible-test \\
                --slave #{install_prefix}/ansible-vault ansible-vault #{sandbox_path}/venv/bin/ansible-vault
            } || {
              echo '===> Ansible is not installed, exiting now. <==='
              exit 1
            }

            echo 'Check alternatives validity'
            #{command_exists("#{install_prefix}/ansible")} || {
              echo '===> Ansible alternative is incorrectly installed, exiting now. <==='
              exit 1
            }
          """
        end

        def search_alternatives
          """
            searchAlternatives() {
              binaryCmd=$1
              #{command_exists("${binaryCmd}")} || {
                alternateCmd=$(ls -1A #{BINARY_DEFAULT_PREFIX}/${binaryCmd}*|grep -v \"${binaryCmd}$\"|sort|head -n1)
                test -n \"${alternateCmd}\" && {
                  echo \"Attempt to install '${alternateCmd}' as an alternative.\"
                  #{command_exists("${alternateCmd}")} && {
                    #{alternatives_command} --install #{BINARY_INSTALL_PREFIX}/${binaryCmd} ${binaryCmd} $(#{check_command("${alternateCmd}")}) 100
                    #{alternatives_command} --set ${binaryCmd} $(#{check_command("${alternateCmd}")})
                  }
                }
              }
            }
          """
        end
      end
    end
  end
end
