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

source 'https://rubygems.org'

gemspec
gem 'test-kitchen',       '~>2.0'
gem 'rugged',             '~>0.25'
gem 'rake'

group :vagrant do
  gem 'kitchen-vagrant',  '~>1.5'
end

group :docker do
  gem 'kitchen-docker',   '~>2.0'
end

group :windows do
  gem 'winrm',            '~>2.3'
  gem 'winrm-fs',         '~>1.2'
end
