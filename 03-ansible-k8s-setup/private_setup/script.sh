sed -i 's/#PermitRootLogin/PermitRootLogin/g' /etc/ssh/sshd_config
sed -i 's/#PasswordAuthentication/PasswordAuthentication/g' /etc/ssh/sshd_config
systemctl restart sshd

# Install epel-release repository on all machines.
yum -y install epel-release
yum -y install ansible

# update /etc/hosts
cat <<EOF >  /etc/hosts
#!/bin/bash
127.0.0.1  localhost localhost.localdomain localhost4 localhost4.localdomain4
::1        localhost localhost.localdomain localhost6 localhost6.localdomain6
10.0.0.99  ansible.example.com ansible
10.0.0.100 master.example.com master
10.0.0.101   nodeone.example.com nodeone
10.0.0.102   nodetwo.example.com nodetwo
EOF
