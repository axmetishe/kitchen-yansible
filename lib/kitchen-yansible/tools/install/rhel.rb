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
              #{update_path}

              installPackage () {
                package=$1
                #{package_manager} -q info ${package} 2>/dev/null|grep installed &>/dev/null || #{install_package} ${package}
              }

              enableSCLPackage () {
                package=$1
                echo \"Enable ${package}\"
                grep \"/opt/rh/${package}/enable\" /etc/profile.d/${package}.sh &> /dev/null || {
                  #{sudo('echo')} \"source /opt/rh/${package}/enable\"| #{sudo('tee')} -a /etc/profile.d/${package}.sh
                }
                source /opt/rh/${package}/enable
              }

              installRubySCL () {
                RUBY_PACKAGE=$(#{package_manager} search -q ruby|grep '^rh-ruby\\([0-9\\.]\\+\\)\\?\\.'|sort -r|head -n1|awk '{print $1}'|awk -F'.' '{print $1}')
                installPackage ${RUBY_PACKAGE}
                RUBY_VERSION=\"$(#{package_manager} info ${RUBY_PACKAGE}|grep -i version|awk '{print $3}')\"
                test -L /usr/lib64/libruby.so.${RUBY_VERSION} || {
                  #{sudo('ln')} -sf /opt/rh/${RUBY_PACKAGE}/root/usr/lib64/libruby.so.${RUBY_VERSION} \\
                    /usr/lib64/libruby.so.${RUBY_VERSION}
                }
                #{ruby_alternatives('/usr/local/bin', "/opt/rh/${RUBY_PACKAGE}/root/usr/bin")}
                enableSCLPackage ${RUBY_PACKAGE}
              }

              installPythonSCL () {
                PYTHON_PACKAGE='python27 python27-python-virtualenv'
                installPackage ${PYTHON_PACKAGE}

                #{alternatives_command} --install /usr/local/bin/python python /opt/rh/python27/root/usr/bin/python 100
                #{alternatives_command} --set python /opt/rh/python27/root/usr/bin/python

                #{sudo('grep')} 'ANSIBLE_PYTHON_INTERPRETER' /etc/profile.d/ansible.sh &> /dev/null || {
                  #{sudo('echo')} \"export ANSIBLE_PYTHON_INTERPRETER=/usr/local/bin/python\"| #{sudo('tee')} -a /etc/profile.d/ansible.sh
                }
                #{sudo('grep')} XDG_DATA_DIRS /etc/sudoers.d/ansible &> /dev/null || {
                  #{sudo('echo')} 'Defaults    env_keep += \"XDG_DATA_DIRS PKG_CONFIG_PATH ANSIBLE_PYTHON_INTERPRETER\"' | #{sudo('tee')} -a /etc/sudoers.d/ansible
                }

                test -L /usr/lib64/libpython2.7.so.1.0 || {
                  #{sudo('ln')} -sf /opt/rh/python27/root/usr/lib64/libpython2.7.so.1.0 \\
                    /usr/lib64/libpython2.7.so.1.0
                }
                test -L /usr/lib64/libpython2.7.so || {
                  #{sudo('ln')} -sf /usr/lib64/libpython2.7.so.1.0 /usr/lib64/libpython2.7.so
                }

                enableSCLPackage 'python27'
              }

              preInstall () {
                RHEL_VERSION=$(test -f /etc/system-release-cpe && awk -F':' '{print $5}' /etc/system-release-cpe || echo '0')
                RHEL_DISTR=$(test -f /etc/system-release-cpe && awk -F':' '{print $3}' /etc/system-release-cpe || echo '0')

                # Sanitize CPE Info
                case ${RHEL_DISTR} in
                  amazon)
                    RHEL_VERSION=6
                    ;;
                  o)
                    RHEL_DISTR=amazon
                    RHEL_VERSION=7
                    ;;
                  *)
                    ;;
                esac

                if [[ ${RHEL_VERSION} -eq 6 || ${RHEL_VERSION} -eq 7 ]]; then
                  echo \"We are going to use SCL repository for Python and Ruby installation\"
                  echo \"Working with ${RHEL_DISTR} ${RHEL_VERSION}\"
                  case ${RHEL_DISTR} in
                    centos)
                      installPackage centos-release-scl-rh
                      installPythonSCL
                      installRubySCL
                      ;;
                    oracle)
                      installPackage oracle-softwarecollection-release-el${RHEL_VERSION}
                      installRubySCL
                      if [[ ${RHEL_VERSION} -eq 6 ]]; then
                        installPythonSCL
                      fi
                      ;;
                    *)
                      echo \"Unsupported RHEL SCL family distribution - ${RHEL_DISTR} ${RHEL_VERSION}\"
                      ;;
                  esac
                fi
                updatePath
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

          def install_ruby
            """
              installRuby () {
                echo 'Checking Ruby installation.'
                searchAlternatives 'ruby'
                #{command_exists('ruby')} || {
                  echo 'Ruby is not installed, attempt to use package manager.'
                  package=$(#{package_manager} search -q ruby 2> /dev/null|grep '^ruby\\([0-9\\.]\\+\\)\\?\\.'|sort -r|head -n1|awk '{print $1}')
                  echo \"Will try to install '${package}' package.\"
                  #{install_package} ${package}
                  echo 'Checking for installed alternatives.'
                  #{command_exists('ruby')} || {
                    searchAlternatives 'ruby'
                  }
                  grep 'gem: --no-rdoc --no-ri -​-no-document' /etc/gemrc &> /dev/null || {
                    #{sudo('echo')} 'gem: --no-rdoc --no-ri -​-no-document' | #{sudo('tee')} /etc/gemrc
                  }
                }
                #{command_exists('ruby')} || {
                  echo \"===> Couldn't determine Ruby executable - exiting now! <===\"
                  exit 1
                }
                echo 'Install Busser'
                #{command_exists('gem')} || {
                  #{install_package} rubygems
                }
                #{command_exists('rdoc')} || {
                  #{install_package} rubygem-rdoc
                }
                #{sudo('gem')} list | grep busser || {
                  #{sudo('gem')} install busser
                }
                test -d /opt/chef/embedded/bin || {
                  #{sudo('mkdir')} -p /opt/chef/embedded/bin
                }
                echo 'Making links for Chef'
                for binary in ruby gem busser; do
                  test -L /opt/chef/embedded/bin/${binary} || {
                    #{sudo('ln')} -sf \"$(command -v ${binary})\" /opt/chef/embedded/bin/${binary}
                  }
                done
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
