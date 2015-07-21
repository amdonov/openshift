useradd git
curl -o /home/git/gogs.zip http://gogs.dn.qbox.me/gogs_v0.6.1_linux_amd64.zip
yum install -y unzip
unzip /home/git/gogs.zip -d /home/git
chown -R git.git /home/git/gogs

cat > /usr/lib/systemd/system/gogs.service << EOF
[Unit]
Description=Gogs (Go Git Service)
After=syslog.target
After=network.target

[Service]
Type=simple
User=git
Group=git
WorkingDirectory=/home/git/gogs
ExecStart=/home/git/gogs/gogs web
Restart=always
Environment="USER=git","HOME=/home/git"

[Install]
WantedBy=multi-user.target
EOF
systemctl enable gogs
systemctl start gogs