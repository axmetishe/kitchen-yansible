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
                echo \"installPrefix: ${installPrefix}\"
                #{command_exists("${binaryCmd}")} || {
                  echo 'Command not found'
                  echo \"search string: ${installPrefix}/${binaryCmd}*\"
                  alternateCmd=$(ls -1A ${installPrefix}/${binaryCmd}*|sort -r|head -n1)
                  echo ${alternateCmd}
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
              preInstall () {
                #{update_path}
                updatePath
              }
            """
          end

          def install_python
            """
              installPython () {
                searchAlternatives python
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
                env
                searchAlternatives 'virtualenv'
                env
                #{command_exists('virtualenv')} || {
                  echo 'Virtualenv is not installed, will try to install via pip.'
                  test -x \"#{BINARY_INSTALL_PREFIX}/pip\" || {
                    #{sudo('easy_install')} pip
                  }
                  #{sudo('pip')} install virtualenv

                  echo 'Checking for installed alternatives.'
                  #{command_exists('virtualenv')} || {
                    searchAlternatives 'virtualenv'
                  }
                }
                #{command_exists('virtualenv')} || {
                  echo \"===> Couldn't install Virtualenv - exiting now! <===\"
                  exit 1
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
                #{sudo('grep')} PATH ~/local.sh &> /dev/null || {
                  #{sudo('echo')} 'export PATH=/usr/local/bin:$PATH' | #{sudo('tee')} -a /etc/profile.d/local.sh
                  #{sudo('chmod')} +x /etc/profile.d/local.sh
                }
              }
            """
          end

          def remote_install
            """
              echo 'Not supported yet'
              exit 1
            """
          end
        end
      end
    end
  end
end
