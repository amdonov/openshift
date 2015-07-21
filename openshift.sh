systemctl disable NetworkManager
systemctl stop NetworkManager
yum remove -y NetworkManager
yum install -y wget git net-tools bind-utils iptables-services bridge-utils docker
systemctl enable docker
cat <<EOF > /etc/sysconfig/docker-storage-setup
DEVS=/dev/sdb
VG=docker-vg
EOF
docker-storage-setup
systemctl stop docker
rm -rf /var/lib/docker/*
systemctl restart docker
cat <<EOF > /etc/yum.repos.d/maxamillion-origin-next.repo
[maxamillion-origin-next]
name=Copr repo for origin-next owned by maxamillion
baseurl=https://copr-be.cloud.fedoraproject.org/results/maxamillion/origin-next/epel-7-\$basearch/
skip_if_unavailable=True
gpgcheck=1
gpgkey=https://copr-be.cloud.fedoraproject.org/results/maxamillion/origin-next/pubkey.gpg
enabled=1
enabled_metadata=1
EOF
echo $1.example.com > /etc/hostname
echo PEERDNS="no" >> /etc/sysconfig/network-scripts/ifcfg-enp0s3
echo nameserver 192.168.56.40 > /etc/resolv.conf
hostname $1.example.com
ifup enp0s8
echo 209.132.184.48 copr-be.cloud.fedoraproject.org >> /etc/hosts