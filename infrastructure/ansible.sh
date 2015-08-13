yum -y install https://dl.fedoraproject.org/pub/epel/7/x86_64/e/epel-release-7-5.noarch.rpm
sed -i -e "s/^enabled=1/enabled=0/" /etc/yum.repos.d/epel.repo
yum -y --enablerepo=epel install ansible git
cd ~
git clone https://github.com/openshift/openshift-ansible
cd openshift-ansible
git checkout 3.0.0-8
cat > /etc/ansible/hosts << EOF
# Create a group that contains the masters and nodes groups
[OSEv3:children]
masters
nodes

# Set variables common for all hosts
[OSEv3:vars]
# SSH user, this user should allow ssh based auth without requiring a password
ansible_ssh_user=root

# If ansible_ssh_user is not root, ansible_sudo must be set to true
#ansible_sudo=true

# To deploy origin, change deployment_type to origin
deployment_type=origin

# enable htpasswd authentication
openshift_master_identity_providers=[{'name': 'htpasswd_auth', 'login': 'true', 'challenge': 'true', 'kind': 'HTPasswdPasswordIdentityProvider', 'filename': '/etc/openshift/openshift-passwd'}]

# host group for masters
[masters]
master.example.com openshift_ip=192.168.56.10 openshift_public_ip=192.168.56.10

# host group for nodes
[nodes]
node1.example.com openshift_ip=192.168.56.20 openshift_public_ip=192.168.56.20
node2.example.com openshift_ip=192.168.56.30 openshift_public_ip=192.168.56.30
EOF
