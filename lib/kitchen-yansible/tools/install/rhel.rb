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
      class Install
        class RHEL < Install
          def preinstall_command
            """
              installPackage () {
                package=$1
                #{package_manager} -q info ${package} 2>/dev/null|grep installed &>/dev/null || #{install_package} ${package}
              }

              preInstall () {
                RHEL_VERSION=$(test -f /etc/system-release-cpe && awk -F':' '{print $5}' /etc/system-release-cpe || echo '0')
                RHEL_DISTR=$(test -f /etc/system-release-cpe && awk -F':' '{print $3}' /etc/system-release-cpe || echo '0')
                test ${RHEL_VERSION} -eq 6 && {
                  echo \"Going to install Python via SCL\"
                  SUPPORTED=1
                  case ${RHEL_DISTR} in
                    rhel)
                      #{sudo('yum-config-manager')} --enable rhel-server-rhscl-6-rpms
                      ;;
                    centos)
                      installPackage 'centos-release-scl-rh'
                      ;;
                    oracle)
                      installPackage 'oracle-softwarecollection-release-el6'
                      ;;
                    *)
                      SUPPORTED=0
                      ;;
                  esac

                  test ${SUPPORTED} -eq 1 && {
                    installPackage 'python27'
                    installPackage 'python27-python-virtualenv'
                    grep '/opt/rh/python27/enable' /etc/profile.d/python27.sh &> /dev/null || {
                      #{sudo('echo')} 'source /opt/rh/python27/enable'| #{sudo('tee')} -a /etc/profile.d/python27.sh
                    }
                    source /opt/rh/python27/enable
                    #{alternatives_command} --install /usr/local/bin/python python /opt/rh/python27/root/usr/bin/python 100
                    #{alternatives_command} --set python /opt/rh/python27/root/usr/bin/python
                    grep 'ANSIBLE_PYTHON_INTERPRETER' /etc/profile.d/ansible.sh &> /dev/null || {
                      #{sudo('echo')} \"export ANSIBLE_PYTHON_INTERPRETER=/usr/local/bin/python\"| #{sudo('tee')} -a /etc/profile.d/ansible.sh
                    }
                    grep XDG_DATA_DIRS /etc/sudoers.d/ansible &> /dev/null || {
                      #{sudo('echo')} 'Defaults    env_keep += \"XDG_DATA_DIRS PKG_CONFIG_PATH ANSIBLE_PYTHON_INTERPRETER\"' | #{sudo('tee')} -a /etc/sudoers.d/ansible
                    }
                    grep /opt/rh/python27 /etc/sudoers.d/ansible &> /dev/null || {
                      #{sudo('echo')} 'Defaults    secure_path = /opt/rh/python27/root/usr/bin:/sbin:/bin:/usr/sbin:/usr/bin' | #{sudo('tee')} -a /etc/sudoers.d/ansible
                    }
                    test -L /usr/lib64/libpython2.7.so.1.0 || #{sudo('ln')} -sf /opt/rh/python27/root/usr/lib64/libpython2.7.so.1.0 /usr/lib64/libpython2.7.so.1.0
                    test -L /usr/lib64/libpython2.7.so || #{sudo('ln')} -sf /usr/lib64/libpython2.7.so.1.0 /usr/lib64/libpython2.7.so
                  } || {
                    echo \"Unsupported RHEL family distribution - ${RHEL_DISTR}\"
                  }
                }
              }
            """
          end

          def install_python
            """
              installPython () {
                echo 'Checking Python installation.'
                searchAlternatives 'python'
                #{command_exists('python')} || {
                  echo 'Python is not installed, attempt to use package manager.'
                  package=$(#{package_manager} search -q python|grep '^python\\([0-9\\.]\\+\\)\\?\\.'|sort -r|head -n1|awk '{print $1}')
                  echo \"Will try to install '${package}' package.\"
                  #{install_package} ${package}
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
                  echo 'Virtualenv is not installed, will try to guess its name.'
                  if [ $(#{package_manager} search virtualenv|grep '^python.*-virtualenv'|wc -l) -gt 1 ]; then
                    venvPackage=python$(#{get_python_version})-virtualenv
                    echo \"Will try to install '${venvPackage}' package.\"
                    #{install_package} ${venvPackage}
                  else
                    echo \"Installing via virtual package.\"
                    #{install_package} python-virtualenv
                  fi

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
