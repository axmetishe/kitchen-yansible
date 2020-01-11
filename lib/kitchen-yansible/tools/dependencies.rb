# Author: Eugene Akhmetkhanov <axmetishe+github@gmail.com>
# Date: 11-01-2020
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

require 'rugged'

module Kitchen
  module Yansible
    module Tools
      module Dependencies
        def git_clone(name, url, path)
          info("Cloning '#{name}' Git repository.")
          Rugged::Repository.clone_at(url, path, { :ignore_cert_errors => true })
        end

        def process_dependencies(dependencies)
          # dependencies_path = @config[:remote_executor] ?  File.join(sandbox_path, 'roles') : instance_sandbox_roles
          dependencies_path = @config[:remote_executor] ? sandbox_path : instance_sandbox_roles
          dependencies.each do |dependency|
            info("Processing '#{dependency[:name]}' dependency.")
            if dependency.key?(:path)
              info('Processing as path type.')
              if File.exist?(dependency[:path])
                copy_files(dependency[:path], File.join(dependencies_path, dependency[:name]))
              else
                warn("Dependency path '#{dependency[:path]}' doesn't exists. Omitting copy operation.")
              end
            end
            if dependency.key?(:repo)
              if dependency[:repo].downcase == 'git'
                info('Processing as Git repository.')
                dependency_path = File.join(dependencies_path, dependency[:name])
                begin
                  repo = Rugged::Repository.new(dependency_path)
                  if repo.remotes.first.url.eql?(dependency[:url])
                    warn("Dependency cloned already.")
                  else
                    warn("Removing directory #{dependency_path} due to repository origin difference.")
                    FileUtils.remove_entry_secure(dependency_path)
                    git_clone(dependency[:name], dependency[:url], dependency_path)
                  end
                rescue
                  if File.exist?(dependency_path)
                    warn("Dependency path '#{dependency_path}' is not a valid Git repository. Removing then.")
                    FileUtils.remove_entry_secure(dependency_path)
                  end
                  repo = git_clone(dependency[:name], dependency[:url], dependency_path)
                end

                raw_ref = dependency.key?(:ref) ? dependency[:ref] : 'master'
                begin
                  repo.rev_parse(raw_ref)
                rescue
                  message = unindent(<<-MSG)

                  ===============================================================================
                   Invalid Git reference - #{raw_ref}
                   Please check '#{dependency[:name]}' dependency configuration.
                  ===============================================================================
                  MSG
                  raise UserError, message
                end

                info("Resetting '#{dependency[:name]}' repository to '#{raw_ref}' reference.")
                repo.checkout(raw_ref, {:strategy => :force})
                repo.close
              else
                raise UserError, "Working with '#{dependency[:repo]}' repository is not implemented yet."
              end
            end
          end
        end
      end
    end
  end
end
