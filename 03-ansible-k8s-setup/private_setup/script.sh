sed -i 's/#PermitRootLogin/PermitRootLogin/g' /etc/ssh/sshd_config
sed -i 's/#PasswordAuthentication/PasswordAuthentication/g' /etc/ssh/sshd_config
systemctl restart sshd

# Install epel-release repository on all machines.
yum -y install epel-release
yum -y install ansible

# Install expect repository on all machines.
yum -y install expect

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

# reset passwd
PASSWORD=oracle
expect <<EOF
spawn passwd root
expect {
  "New password:" {send "${PASSWORD}\n";exp_continue}
  "Retype new password:" {send "${PASSWORD}\r"}
}
expect eof
EOF

# Timezone setup
timedatectl set-timezone Asia/Shanghai

# generate ssh keys on Ansible Controller and copy ssh key to master/nodeone/nodetwo
if [ $HOSTNAME = "ansible.example.com" ] ; then
expect <<EOF
spawn ssh-keygen
expect {
  "Enter file in which to save the key (/root/.ssh/id_rsa):" {send "\r";exp_continue}
  "Enter passphrase (empty for no passphrase):" {send "\r";exp_continue}
  "Enter same passphrase again:" {send "\r\n"}
}
expect eof
EOF

expect <<EOF
spawn ssh-copy-id -i  root@master.example.com
expect {
    "yes/no" { send "yes\n";exp_continue }
    "password" { send "${PASSWORD}\n" }
}
expect eof
EOF

expect <<EOF
spawn ssh-copy-id -i  root@nodeone.example.com
expect {
    "yes/no" { send "yes\n";exp_continue }
    "password" { send "${PASSWORD}\n" }
}
expect eof
EOF

expect <<EOF
spawn ssh-copy-id -i  root@nodetwo.example.com
expect {
    "yes/no" { send "yes\n";exp_continue }
    "password" { send "${PASSWORD}\n" }
}
expect eof
EOF

#expect <<EOF
#spawn su - root
#expect {
#    "Password:" { send "${PASSWORD}\n" }
#}
#expect eof
#EOF

cd /vagrant
ansible-playbook k8s-pkg.yml
ansible-playbook k8s-master.yml
ansible-playbook k8s-workers.yml
fi