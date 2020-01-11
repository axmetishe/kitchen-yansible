# kitchen-yansible

Yet Another Ansible [Test Kitchen](https://github.com/test-kitchen/test-kitchen) Provisioner

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
Why is that mean? - Well, Ansible was created as master-less configuration management tool for simple management from
any place without dedicated master, so the provisioner for Ansible must have the same behaviour obviously.
Despite the fact I'm not an Ansible fan I like when tool is used at purpose -you wouldn't want to use a microscope to
hammer a nail=) 

To be continued...
