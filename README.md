Bring up the infrastructure vm.
Bring up master, node1, and node2 vms in any order.
Login into infrastructure and run the following commands.
sudo -s
ssh-keygen
ssh-copy-id master.example.com
ssh-copy-id node1.example.com
ssh-copy-id node2.example.com
ansible-playbook ~/openshift-ansible/playbooks/byo/config.yml

Create a user on master
# htpasswd /etc/openshift/openshift-passwd amdono

