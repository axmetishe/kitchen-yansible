# kitchen-yansible

Yet Another Ansible [Test Kitchen](https://github.com/test-kitchen/test-kitchen) Provisioner

[![Build Status](https://travis-ci.org/axmetishe/kitchen-yansible.svg?branch=develop)](https://travis-ci.org/axmetishe/kitchen-yansible)

## Why another
For a long time I used to work with SaltStack with integration testing for at least two platforms and it was
a great experience, special thanks to eco-system created by SaltStack team and [Daniel Wallace](https://github.com/gtmanfred)
for his 'salt-solo' provisioner especially.

Now I'm working with Ansible and just want to maintain the same development comfort as with SaltStack.

As was mentioned before this plugin was inspired by three other provisioners with different configuration behaviour and
even another configuration management tool provisioner:
[kitchen-ansible](https://github.com/neillturner/kitchen-ansible) - installation on the instance under test and execution against localhost
[kitchen-ansiblepush](https://github.com/ahelal/kitchen-ansiblepush) - Ansible execution from host system on the instance under test
[kitchen-salt](https://github.com/saltstack/kitchen-salt) - SaltStack CM tool provisioner

Both Ansible provisioners are good at their purpose but when you are working with different platforms especially
with the triple at same time you have to use different provisioners.
For instance 'kitchen-ansible' has dependency management but is able to test Windows platform only using linux
test instance provisioned at the same time, on the other hand 'ansible-push' is able to test Windows directly but
has nothing to work with dependencies unfortunately and you will have to manage them manually or using
third-party tools like 'librarian-ansible', ansible-galaxy or something other.

SaltStack provisioner has all of this and I'm going to provide the same functionality for the Ansible.

Yes, I know about [Molecule](https://github.com/ansible/molecule) which is designed to work with Ansible, but it limited
to Ansible only and looks not so powerful for me as the Test Kitchen, moreover I saw a lot of Dev cases when you
have no ability to pin to specific system and, in general, why you even would to limit yourself?=)

## About
This provider has two major features - local and remote execution using single provisioner.

Why is that matter? - Well, Ansible was created as masterless/agentless configuration management tool for simple
management from any place without dedicated master, so the provisioner for Ansible must have the same behaviour obviously.
Despite the fact I'm not an Ansible fan I like when tool is used at purpose - you wouldn't want to use a microscope to
hammer a nail=)

On the other hand Ansible modules would not work without Python installed(agentless - heh=) on instance under test
which are force us to manage Python installation for containerized instances and in case we need to install Python,
why we can't install Ansible as well?
Or maybe you just don't want to install some Python dependencies locally required for Ansible?
That is why remote installation is also takes a place.

## How to install
`gem build kitchen-yansible.gemspec && gem install kitchen-yansible-0.0.1.gem` as for now.

TDB

## How to use
You need to install the gem and define the provisioner in general.
```yaml
provisioner:
  name: yansible
```

### Default configuration
The simple configuration above will initialize provisioner with default options like:
- Local Ansible execution, e.g. "push" mode.
- In case Ansible is not installed locally we will try to use Python Virtualenv binary in order to install latest
Ansible into instance sandbox directory.
- When we will be able to use Ansible we will run it against 'default.yml' playbook at the kitchen root diretory

### Provisioner options
```yaml
provisioner:
  name: yansible

  # Defines the version of Ansible to install into sandbox or on the instance under test
  ansible_version: 2.7.12

  # Forces sandbox creation on the host for "push" mode even Ansible is installed locally
  sandboxed_executor: true

  # Switch executor to remote installation on instance under test - except for Windows platform
  remote_executor: true

  # Enable Ansible verbose output - '-v'
  ansible_verbose: true

  # Ansible verbosity level - '-vvvv'
  ansible_verbosity: 4

  # Dependencies management
  dependencies:
    # Path dependency - will be copied into sandbox recursively, excluding '.git/' directory
    - name: 'jdk'
      # Relative or absolute path to the role root directory
      path: '../jdk/roles/jdk'

    # Git dependency - will be cloned using shallow clone to specified git ref
    - name: 'mysql'
      # Only Git VCS supported at the moment
      repo: 'git'
      url: 'https://github.com/geerlingguy/ansible-role-mysql.git'
      # Valid git ref, e.g. branch, tag, or even commit hash
      ref: '1.6.0'

  # Allow to change main executable binary
  ansible_binary: 'ansible-playbook'

  # Copy to sandbox and enable Ansible config usage
  ansible_config: nil

  # Override default roles directory
  ansible_roles_path: 'roles'

  # Extra arguments to pass to Ansible command as-is
  ansible_extra_arguments:
    - '-e "version=1.23.45 other_variable=foo"'

  # Force colorized stdout
  ansible_force_color: true

  # Disable/Enable host key check
  ansible_host_key_checking: false

  # Auth transport for WinRM - 'Basic' if not defined
  ansible_winrm_auth_transport: nil

  # Ignore WinRM connection certificate issues - 'ignore', 'validate'
  ansible_winrm_cert_validation: 'ignore'
```

### Complex example
```yaml
driver:
  name: docker

provisioner:
  name: yansible
  ansible_verbose: true
  dependencies:
    - name: 'jdk'
      path: '../jdk/roles/jdk'
    - name: 'mysql'
      repo: 'git'
      url: 'https://github.com/geerlingguy/ansible-role-mysql.git'
      ref: '1eee6e262bff56094398cbb285b44634b9763349'
  ansible_extra_arguments:
    - '-e "version=1.23.45 other_variable=foo"'

platforms:
  # Vagrant driver
  - name: ubuntu-vagrant
    driver:
      name: vagrant
      provider: libvirt
      box: generic/ubuntu1804

  # Make sure that Windows box template forward WinRM ports, winrm transport and
  # user credentials are correct
  - name: windows
    transport:
      name: winrm
      username: 'user'
      password: 'user'
      winrm_transport: :ssl
    driver:
      name: vagrant
      provider: libvirt
      box: local/windows
      vagrantfile_erb: 'Vagrant-template'
    driver_config:
      communicator: winrm
    provisioner:
      remote_executor: false

  # Docker driver
  ## RHEL-based
  - name: centos-6
  - name: centos-7
    driver_config:
      provision_command:
        - yum install -y unzip tar
  - name: centos-8
  - name: oraclelinux-6
  - name: oraclelinux-7
  - name: oraclelinux-8
  - name: fedora-26
  - name: fedora-27
  - name: fedora-28
  - name: fedora-29
  - name: fedora-30
  - name: fedora-31
  - name: amazonlinux-1
  - name: amazonlinux-2

  ## Debian-based
  - name: debian-7
    driver_config:
      image: local/debian:7
  - name: debian-8
  - name: debian-9
  - name: debian-10
  - name: ubuntu-14.04
  - name: ubuntu-16.04
  - name: ubuntu-18.04
  - name: ubuntu-19.04
  - name: ubuntu-19.10

  # Docker driver, systemd init system
  - name: centos-8-systemd
    driver:
      volume: /sys/fs/cgroup:/sys/fs/cgroup:ro
      cap_add:
        - SYS_ADMIN
    driver_config:
      image: local/centos8-systemd:1.0
      run_command: /sbin/init
  - name: amazonlinux-2-systemd
    driver:
      volume: /sys/fs/cgroup:/sys/fs/cgroup:ro
      cap_add:
        - SYS_ADMIN
    driver_config:
      image: local/amazonlinux2-systemd:1.0
      run_command: /usr/sbin/init
  - name: ubuntu-18.04-systemd
    driver:
      volume: /sys/fs/cgroup:/sys/fs/cgroup:ro
      cap_add:
        - SYS_ADMIN
    driver_config:
      image: local/ubuntu18.04-systemd:1.0
      run_command: /lib/systemd/systemd
```

## TODO

* Dependencies mgmt - librarian-ansible
* Remote installation via pkgmgr
* Platforms:
  * Darwin
  * Alpine
  * Suse
  * *BSD
