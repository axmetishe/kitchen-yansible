# Author: Eugene Akhmetkhanov <axmetishe+github@gmail.com>
# Date: 10-01-2020
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
        class Debian < Install
          def package_manager
            "#{sudo_env('apt-get')}"
          end

          def update_cache
            "#{package_manager} update"
          end

          def alternatives_command
            "#{sudo('update-alternatives')}"
          end

          def preinstall_command
            """
              preInstall () {
                ## Fix debconf tty warning messages
                export DEBIAN_FRONTEND=noninteractive

                ## https://github.com/neillturner/kitchen-ansible/blob/master/lib/kitchen/provisioner/ansible/os/debian.rb#L43
                ## Install apt-utils to silence debconf warning: http://serverfault.com/q/358943/77156
                ## Install dirmngr to handle GPG key management for stretch,
                ## addressing https://github.com/neillturner/kitchen-ansible/issues/257
                #{install_package} apt-utils dirmngr

                source /etc/*release*
                if [[ \"${ID}\" = \"debian\" && \"${VERSION_ID}\" = \"7\" ]]; then
                  echo 'Switching Debian Wheezy to archive repository'
                  sed -i -e \"s@deb.\\(debian.org\\)@archive.\\1@g;s@\\(.*updates\\)@#\\1@g\" /etc/apt/sources.list
                  PIP_ARGS=\"-i https://pypi.python.org/simple/\"
                fi
              }
            """
          end

          def install_python
            """
              installPython () {
                echo 'Checking Python installation.'
                #{command_exists('python')} || {
                  echo 'Python is not installed, attempt to install via virtual packages.'
                  #{install_package} python
                  echo 'Checking for installed alternatives.'
                  #{command_exists('python')} || {
                    searchAlternatives 'python'
                  }
                }
                #{command_exists('python')} || {
                  echo \"===> Couldn't determine Python executable - exiting now! <===\"
                  exit 1
                }
              }
            """
          end

          def install_virtualenv
            """
              installVirtualenv () {
                echo 'Checking Virtualenv installation.'
                searchAlternatives 'virtualenv'
                #{command_exists('virtualenv')} || {
                  echo 'Attempt to guess Virtualenv package.'
                  venvPackage=python$(python -c 'import sys; print(\"\".join(map(str, sys.version_info[:#{PYTHON_VERSION_SIZE}])))')-virtualenv
                  #{install_package} ${venvPackage}||#{install_package} python-virtualenv
                  #{install_package} virtualenv

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
        end
      end
    end
  end
end
