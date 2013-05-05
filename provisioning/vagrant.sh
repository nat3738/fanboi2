#!/usr/bin/env bash
# --------------------------------------------------------------------------
# This script bootstrap Ansible on Vagrant box and use the Ansible playbook
# to setup itself. It should only be used by Vagrant. We need to run Ansible
# in local mode in order to support bootstrapping Vagrant box on Windows.
# --------------------------------------------------------------------------

PROVISIONING=/vagrant/provisioning
PLAYBOOK=$PROVISIONING/playbook.yml
HOSTS=$PROVISIONING/ansible_hosts

# Install pip if not already installed.
which pip >/dev/null
if [ "$?" -eq "1" ]; then
    echo "Installing setuptools..."
    apt-get install -y python-setuptools
    easy_install pip
fi

# Install ansible if not already installed.
which ansible >/dev/null
if [ "$?" -eq "1" ]; then
    echo "Bootstrapping ansible..."
    pip install ansible
fi

# Run Ansible in local mode.
ansible-playbook --connection=local -i $HOSTS $PLAYBOOK
