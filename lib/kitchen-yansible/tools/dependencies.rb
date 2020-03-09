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

module Kitchen
  module Yansible
    module Tools
      module Dependencies
        def git_clone(name, url, path)
          info("Cloning '#{name}' Git repository.")
          execute_local_command("git clone --progress --verbose #{url} #{path}")
        end

        def git_get_origin(path)
          debug("Get '#{path}' origin.")
          execute_local_command( 'git remote get-url origin', opts: { :chdir => path }, return_stdout: true )
        end

        def git_clean(path)
          debug("Cleaning up '#{path}' origin.")
          execute_local_command('git clean -fdx', opts: { :chdir => path })
          execute_local_command('git reset --hard', opts: { :chdir => path })
        end

        def git_checkout(path, ref, force: false)
          debug("Checking out #{ref} on #{path}.")
          execute_local_command("git checkout #{ref}#{force ? ' -f' : ''}", opts: { :chdir => path })
        end

        def git_check_ref(path, ref)
          debug("Checking out #{ref} on #{path}.")
          execute_local_command("git show-ref #{ref}", opts: { :chdir => path })
        end

        def prepare_dependencies(dependencies)
          dependencies.each do |dependency|
            info("Processing '#{dependency[:name]}' dependency.")
            dependency_target_path = File.join(dependencies_tmp_dir, dependency[:name])
            if dependency.key?(:path)
              info('Processing as path type.')
              if File.exist?(dependency[:path])
                copy_dirs(dependency[:path], dependency_target_path)
              else
                warn("Dependency path '#{dependency[:path]}' doesn't exists. Omitting copy operation.")
              end
            end
            if dependency.key?(:repo)
              if dependency[:repo].downcase == 'git'
                info('Processing as Git repository.')
                if command_exists('git')
                  if File.exist?(dependency_target_path)
                    if execute_local_command('git status .', opts: { :chdir => dependency_target_path })
                      if git_get_origin(dependency_target_path).chomp.eql?(dependency[:url])
                        warn("Dependency downloaded already, resetting to HEAD.")
                        git_clean(dependency_target_path)
                      else
                        warn("Removing directory #{dependency_target_path} due to repository origin difference.")
                        FileUtils.remove_entry_secure(dependency_target_path)
                        git_clone(dependency[:name], dependency[:url], dependency_target_path)
                      end
                    else
                      warn("Dependency path '#{dependency_target_path}' is not a valid Git repository. Removing then.")
                      FileUtils.remove_entry_secure(dependency_target_path)
                      git_clone(dependency[:name], dependency[:url], dependency_target_path)
                    end
                  else
                    git_clone(dependency[:name], dependency[:url], dependency_target_path)
                  end

                  raw_ref = dependency.key?(:ref) ? dependency[:ref] : 'master'
                  begin
                    git_check_ref(dependency_target_path, raw_ref)
                  rescue
                    message = unindent(<<-MSG)

                      ===============================================================================
                       Invalid Git reference - #{raw_ref}
                       Please check '#{dependency[:name]}' dependency configuration.
                      ===============================================================================
                    MSG
                    raise UserError, message
                  end

                  info("Resetting repository to '#{raw_ref}' reference.")
                  git_checkout(dependency_target_path, raw_ref, force: true)
                else
                  message = unindent(<<-MSG)

                    ===============================================================================
                     Couldn't find git binary.
                     Please make sure execution host has Git binaries installed.
                    ===============================================================================
                  MSG
                  raise UserError, message
                end
              else
                raise UserError, "Working with '#{dependency[:repo]}' repository is not implemented yet."
              end
            end
          end unless dependencies.nil?
        end
      end
    end
  end
end
