yum install -y bind bind-utils
domain=example.com
keyfile=/var/named/${domain}.key
pushd /var/named
rm -f K${domain}*
dnssec-keygen -a HMAC-MD5 -b 512 -n USER -r /dev/urandom ${domain}
KEY="$(grep Key: K${domain}*.private | cut -d ' ' -f 2)"
popd
rndc-confgen -a -r /dev/urandom
restorecon -v /etc/rndc.* /etc/named.*
chown -v root:named /etc/rndc.key
chmod -v 640 /etc/rndc.key
echo "forwarders { 8.8.8.8; 8.8.4.4; } ;" > /var/named/forwarders.conf
restorecon -v /var/named/forwarders.conf
chmod -v 640 /var/named/forwarders.conf
rm -rvf /var/named/dynamic
mkdir -vp /var/named/dynamic
cat <<EOF > /var/named/dynamic/${domain}.db
\$ORIGIN .
\$TTL 1 ; 1 seconds (for testing only)
${domain}       IN SOA  ns1.${domain}. hostmaster.${domain}. (
            2011112904 ; serial
            60         ; refresh (1 minute)
            15         ; retry (15 seconds)
            1800       ; expire (30 minutes)
            10         ; minimum (10 seconds)
            )
        NS  ns1.${domain}.
        MX  10 mail.${domain}.
\$ORIGIN ${domain}.
ns1         A   127.0.0.1
EOF
cat <<EOF > /var/named/${domain}.key
key ${domain} {
  algorithm HMAC-MD5;
  secret "${KEY}";
};
EOF
chown -Rv named:named /var/named
restorecon -rv /var/named
cat <<EOF > /etc/named.conf
// named.conf
//
// Provided by Red Hat bind package to configure the ISC BIND named(8) DNS
// server as a caching only nameserver (as a localhost DNS resolver only).
//
// See /usr/share/doc/bind*/sample/ for example named configuration files.
//

options {
    listen-on port 53 { any; };
    directory   "/var/named";
    dump-file   "/var/named/data/cache_dump.db";
        statistics-file "/var/named/data/named_stats.txt";
        memstatistics-file "/var/named/data/named_mem_stats.txt";
    allow-query     { any; };
    recursion yes;

    /* Path to ISC DLV key */
    bindkeys-file "/etc/named.iscdlv.key";

    // set forwarding to the next nearest server (from DHCP response
    forward only;
    include "forwarders.conf";
};

logging {
        channel default_debug {
                file "data/named.run";
                severity dynamic;
        };
};

// use the default rndc key
include "/etc/rndc.key";

controls {
    inet 127.0.0.1 port 953
    allow { 127.0.0.1; } keys { "rndc-key"; };
};

include "/etc/named.rfc1912.zones";

include "${domain}.key";

zone "${domain}" IN {
    type master;
    file "dynamic/${domain}.db";
    allow-update { key ${domain} ; } ;
};
EOF
chown -v root:named /etc/named.conf
restorecon /etc/named.conf
systemctl enable named
systemctl start named
cat << EOF | nsupdate -k ${keyfile}
server 127.0.0.1
update delete master.example.com A
update add master.example.com 180 A 192.168.56.10
update delete node1.example.com A
update add node1.example.com 180 A 192.168.56.20
update delete node2.example.com A
update add node2.example.com 180 A 192.168.56.30
update delete infrastructure.example.com A
update add infrastructure.example.com 180 A 192.168.56.40
send
quit
EOF
systemctl disable NetworkManager
systemctl stop NetworkManager
yum remove -y NetworkManager
echo infrastructure.example.com > /etc/hostname
echo PEERDNS="no" >> /etc/sysconfig/network-scripts/ifcfg-enp0s3
echo nameserver 127.0.0.1 > /etc/resolv.conf
hostname infrastructure.example.com
ifup enp0s8
