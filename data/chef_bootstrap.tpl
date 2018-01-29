#!/bin/bash

set -e
echo "Setting up knife.rb, gd-config.rb, /etc/cron.d/gd"
chown root:root /root/.chef/knife.rb
chown root:root /etc/gd-config.rb
chmod 0755 /etc/cron.d/gd


apt-get update

apt-get install git -y

#################################################
# Install chef server
#################################################

wget -O /tmp/chef-server-core_${chef_version}_amd64.deb https://packages.chef.io/files/stable/chef-server/${chef_version}/ubuntu/${os_version}/chef-server-core_${chef_version}-1_amd64.deb
dpkg -i /tmp/chef-server-core_${chef_version}_amd64.deb
apt-get install cmake -y
apt-get install pkg-config -y
service cron restart  # restart cron to load the gd job

#################################################
# Default chef config
#################################################
mkdir -p /etc/opscode/
chef-server-ctl reconfigure
chef-server-ctl user-create ${chef_username} ${chef_first_name} ${chef_last_name} ${chef_user_email} '${chef_password}' --filename /root/.chef/${chef_username}.pem
chef-server-ctl org-create ${chef_organization_id} "${chef_organization_name}" --association_user ${chef_username} --filename /root/.chef/${chef_organization_id}-validator.pem

#################################################
# Chef validator ACL updates
#################################################
# Install knife-acl
/opt/opscode/embedded/bin/gem install knife-acl

# Create validators group
/opt/opscode/embedded/bin/knife group create ${chef_organization_id}-validators

# Add ${chef_organization_id}-validator (it is made when you create an org) to newly created validator group
/opt/opscode/embedded/bin/knife group add client ${chef_organization_id}-validator ${chef_organization_id}-validators


# Add clients permission for newly created validator group
/opt/opscode/embedded/bin/knife acl add group ${chef_organization_id}-validators containers clients read
/opt/opscode/embedded/bin/knife acl add group ${chef_organization_id}-validators containers clients create
/opt/opscode/embedded/bin/knife acl add group ${chef_organization_id}-validators containers clients update
/opt/opscode/embedded/bin/knife acl add group ${chef_organization_id}-validators containers clients grant

# Add nodes permission for newly created validator group
/opt/opscode/embedded/bin/knife acl add group ${chef_organization_id}-validators containers nodes read
/opt/opscode/embedded/bin/knife acl add group ${chef_organization_id}-validators containers nodes create
/opt/opscode/embedded/bin/knife acl add group ${chef_organization_id}-validators containers nodes update
/opt/opscode/embedded/bin/knife acl add group ${chef_organization_id}-validators containers nodes grant


# Setup grocery-delivery
/opt/opscode/embedded/bin/gem install grocery_delivery

# SSH check with Github



#################################################
# Finished Statement
#################################################
echo "Finished!!!"
