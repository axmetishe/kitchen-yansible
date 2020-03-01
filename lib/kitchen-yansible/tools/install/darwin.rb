# Author: Eugene Akhmetkhanov <axmetishe+github@gmail.com>
# Date: 27-02-2020
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
      class Install
        class Darwin < Install
          def search_alternatives
            """
              searchAlternatives() {
                binaryCmd=$1
                test -n \"${2}\" && installPrefix=\"${2}\" || installPrefix=#{BINARY_DEFAULT_PREFIX}
                #{command_exists("${binaryCmd}")} || {
                  alternateCmd=$(ls -1A ${installPrefix}/${binaryCmd}*|sort -r|head -n1)
                  test -n \"${alternateCmd}\" && {
                    echo \"Attempt to install '${alternateCmd}' as an alternative.\"
                    #{sudo('ln')} -sf \"${alternateCmd}\" #{BINARY_DEFAULT_PREFIX}/${binaryCmd}
                  }
                }
              }
            """
          end

          def preinstall_command
            """
              #{update_path}

              preInstall () {
                updatePath
              }
            """
          end

          def install_python
            """
              installPython () {
                PYTHON_CMD='/usr/bin/python3'
                #{command_exists("${PYTHON_CMD}")} || {
                  PYTHON_CMD='/usr/bin/python'
                }
                grep 'ANSIBLE_PYTHON_INTERPRETER' ~/.profile &> /dev/null || {
                  echo \"ANSIBLE_PYTHON_INTERPRETER=${PYTHON_CMD}\" >> ~/.profile
                  echo 'export ANSIBLE_PYTHON_INTERPRETER' >> ~/.profile
                }
                #{sudo('grep')} ANSIBLE_PYTHON_INTERPRETER /etc/sudoers.d/ansible &> /dev/null || {
                  #{sudo('echo')} 'Defaults    env_keep += \"ANSIBLE_PYTHON_INTERPRETER\"' | #{sudo('tee')} -a /etc/sudoers.d/ansible
                }

                source ~/.profile
              }
            """
          end

          def install_ruby
            """
              installRuby () {
                searchAlternatives ruby
                echo 'Install Busser'
                #{sudo('gem')} list | grep busser || {
                  #{sudo('gem')} install busser
                }
                test -d /opt/chef/embedded/bin || {
                  #{sudo('mkdir')} -p /opt/chef/embedded/bin
                }
                echo 'Making links for Chef'
                for binary in ruby gem busser; do
                  test -L /opt/chef/embedded/bin/${binary} || {
                    #{sudo('ln')} -sf $(command -v ${binary}) /opt/chef/embedded/bin/${binary}
                  }
                done
              }
            """
          end

          def install_virtualenv
            """
              installVirtualenv () {
                echo 'Checking Virtualenv installation.'

                ${ANSIBLE_PYTHON_INTERPRETER} -c 'help(\"modules\")'|grep ' pip ' &>/dev/null || {
                  ${ANSIBLE_PYTHON_INTERPRETER} -m ensurepip
                }
                ${ANSIBLE_PYTHON_INTERPRETER} -m pip list|grep 'virtualenv' &>/dev/null || {
                  ${ANSIBLE_PYTHON_INTERPRETER} -m pip install --user virtualenv
                }
              }
            """
          end

          def update_path
            """
              updatePath () {
                #{sudo('grep')} secure_path /etc/sudoers.d/ansible &> /dev/null || {
                  #{sudo('echo')} 'Defaults    secure_path = /usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin' | #{sudo('tee')} -a /etc/sudoers.d/ansible
                }

                grep 'PATH=/usr/local/bin:$PATH' ~/.profile &> /dev/null || {
                  echo 'PATH=/usr/local/bin:$PATH' >> ~/.profile
                  echo 'export PATH' >> ~/.profile
                }
                source ~/.profile
              }
            """
          end

          def install_ansible_pip(sandbox_path)
            """
              installAnsiblePip () {
                echo \"Installing Ansible via Pip\"
                VENV_MODULE=virtualenv
                echo ${ANSIBLE_PYTHON_INTERPRETER} | grep 3 &>/dev/null && {
                  VENV_MODULE=venv
                }
                test -f #{sandbox_path}/venv/bin/pip || {
                  mkdir -p #{sandbox_path}
                  ${ANSIBLE_PYTHON_INTERPRETER} -m ${VENV_MODULE} #{sandbox_path}/venv
                  #{sandbox_path}/venv/bin/pip install $PIP_ARGS --upgrade pip setuptools
                }
                #{sandbox_path}/venv/bin/pip install $PIP_ARGS #{pip_required_packages.join(' ')}

                #{ansible_alternatives(BINARY_INSTALL_PREFIX, sandbox_path)}
              }
            """
          end

          def ansible_alternatives(install_prefix, sandbox_path)
            """
              #{command_exists("#{sandbox_path}/venv/bin/ansible")} && {
                ansibleCommands=( \\
                  ansible \\
                  ansible-config \\
                  ansible-connection \\
                  ansible-console \\
                  ansible-doc \\
                  ansible-galaxy \\
                  ansible-inventory \\
                  ansible-playbook \\
                  ansible-pull \\
                  ansible-test \\
                  ansible-vault \\
                )
                for ansibleCommand in \"${ansibleCommands[@]}\"; do
                  #{sudo('ln -sf')} #{sandbox_path}/venv/bin/${ansibleCommand} #{install_prefix}/${ansibleCommand}
                done
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
        end
      end
    end
  end
end
