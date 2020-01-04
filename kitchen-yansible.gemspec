# Author: Eugene Akhmetkhanov <axmetishe+github@gmail.com>
# Date: 03-01-2020
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

$LOAD_PATH.unshift File.expand_path('../lib', __FILE__)
require 'kitchen-yansible/version'

Gem::Specification.new do |s|
  s.name                        = 'kitchen-yansible'
  s.license                     = 'Apache-2.0'
  s.version                     = Kitchen::Yansible::VERSION
  s.authors                     = ['Eugene Akhmetkhanov']
  s.email                       = ['axmetishe+github@gmail.com']
  s.homepage                    = 'https://github.com/axmetishe/kitchen-yansible'
  s.summary                     = 'Yet Another Ansible Test-Kitchen Provisioner'
  s.files                       = (Dir.glob('{lib}/**/*') + ['kitchen-yansible.gemspec']).sort
  s.platform                    = Gem::Platform::RUBY
  s.require_paths               = ['lib']
  s.rubyforge_project           = '[none]'
  s.description                 = 'Yet Another Ansible Test-Kitchen Provisioner'

  s.add_runtime_dependency      'test-kitchen', '~> 2.0'
end
