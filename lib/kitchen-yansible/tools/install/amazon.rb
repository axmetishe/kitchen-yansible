# Author: Eugene Akhmetkhanov <axmetishe+github@gmail.com>
# Date: 08-01-2020
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
        class Amazon < RHEL
          def python_version_size
            2
          end

          def preinstall_command
            """
              installPackage () {
                package=$1
                #{package_manager} -q info ${package} 2>/dev/null|grep installed &>/dev/null || #{install_package} ${package}
              }

              installPackageExtras () {
                package=$1
                #{package_manager} -q info ${package} 2>/dev/null|grep installed &>/dev/null || #{sudo('amazon-linux-extras')} install -y ${package}
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

                if [[ ${RHEL_VERSION} -eq 7 ]]; then
                  #{command_exists("ruby")} || {
                    echo \"Installing Ruby via Amazon Extras repository\"
                    RUBY_PACKAGE=$(#{sudo('amazon-linux-extras')} list|grep 'ruby\\([0-9\\.]\\+\\)\\?\\.'|sort -r|head -n1|awk '{print $2}')
                    installPackageExtras ${RUBY_PACKAGE}
                    installPackage rubygem-rdoc
                  }
                fi
              }
            """
          end
        end
      end
    end
  end
end
