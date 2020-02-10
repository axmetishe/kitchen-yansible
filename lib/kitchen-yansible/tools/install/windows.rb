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

require 'uri'

module Kitchen
  module Yansible
    module Tools
      class Install
        class Windows < Install
          def pip_required_packages
            [
              "ansible#{pip_version(ansible_version)}",
              "pywinrm"
            ]
          end

          def install_win_software(url, distr_dir, install_dir, install_arguments, test_binary )
            """
              $downloadUrl = \"#{url}\"
              $distrDir=\"#{distr_dir}\"
              $installerName = \"#{File.basename(URI.parse(url).path)}\"
              $installDir=\"#{install_dir}\"
              $testBinary=\"#{test_binary}\"
              mkdir $distrDir -Force | out-null
              mkdir $installDir -Force | out-null

              try {
                if (! (Test-Path \"${distrDir}\\${installerName}\") ) {
                  echo \"Downloading ${installerName}\"
                  Invoke-WebRequest -DisableKeepAlive -UseBasicParsing -Method GET -Uri \"${downloadUrl}\" -OutFile \"${distrDir}\\${installerName}\"
                }
                if (! (Test-Path \"${installDir}\\${testBinary}\") ) {
                  echo \"Installing ${installerName}\"
                  $p = Start-Process -Wait -Passthru -FilePath \"${distrDir}\\${installerName}\" -ArgumentList #{install_arguments.join(', ')}

                  if ($p.ExitCode -ne 0) {
                    throw \"${installerName} installation was not successful. Received exit code $($p.ExitCode)\"
                  }
                } else {
                  echo \"Installed already. Skipping.\"
                }
              }
              catch {
                Write-Error ($_ | ft -Property * | out-string) -ErrorAction Continue
                exit 1
              }
            """
          end

          def install_python
            python_version='3.7.6'
            base_url="https://www.python.org/ftp/python/#{python_version}"
            installer_name = "python-#{python_version}-amd64.exe"
            download_url = "#{base_url}/#{installer_name}"
            base_dir='C:\\python'
            distr_dir="#{base_dir}\\distr"
            install_dir="#{base_dir}\\install"
            install_args = [ '/passive', 'InstallAllUsers=1', 'PrependPath=1', "TargetDir=\"#{install_dir}\"", '/quiet' ]

            """
              #{install_win_software(download_url, distr_dir, install_dir, install_args, "bin\\python.exe")}
            """
          end

          def install_ruby
            ruby_version='2.6.5-1'
            base_url="https://github.com/oneclick/rubyinstaller2/releases/download/RubyInstaller-#{ruby_version}"
            installer_name = "rubyinstaller-#{ruby_version}-x64.exe"
            download_url = "#{base_url}/#{installer_name}"
            base_dir='C:\\opscode\\chef'
            distr_dir="#{base_dir}\\distr"
            install_dir="#{base_dir}\\embedded"
            install_args = [ '/silent', '/lang=en', '/tasks="assocfiles,modpath"', "/dir=\"#{install_dir}\"" ]

            """
              #{install_win_software(download_url, distr_dir, install_dir, install_args, "bin\\ruby.exe")}
            """
          end

          def local_install
            """
              $ErrorActionPreference = 'Stop'

              #{install_python}
              #{install_ruby}
            """
          end

          def remote_install
            "echo 'Not supported'"
          end
        end
      end
    end
  end
end
