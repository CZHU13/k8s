## k8s with ansible on centos7

If you know Ansible .  
You can use ansible ti setup your kubernetes cluster in couple of minutes.  

This is actually the approach companies use to build kubernetes cluster in  
production environment . No one has time to build things manually.  

Doing things manually is good for learning perspective.  

## prerequisites

Before you move ahead . These are the pre-requisites.

1. linux skills . Specially SHH configuration and authentication 

2. ansible skills .

## Virtual machines setup needed
(Network Interface Card) : NIC  网卡  
ensure your vm machines can access the internet.  
### 1.Ansible controller - controller.example.com
OS:CentOS 7               
CPU cores - 1  
RAM: 2 GiB              
NIC's - a.NAT b.internal  
Internet connectivity - Internal NIC IP - 10.0.0.99/8  

### 2.Kubernetes Master - master.example.com  
OS - Centos 7  
CPU Cores - 2  
RAM - 4 GiB  
NIC - a. NAT b. Internal  
Internet connectivity - Internal NIC IP - 10.0.0.100/8  

### 3.Kubernetes Node - nodeone.example.com
OS - Centos 7  
CPU Cores - 1  
RAM - 2 GiB  
NIC - a. NAT b.Internal  
Internet connectivity - Internal NIC IP - 10.0.0.101/8  


### 4.Kubernetes Node - nodetwo.example.com
OS - Centos 7  
CPU Cores - 1  
RAM - 2 GiB  
NIC - a. NAT b.Internal  
Internet connectivity - Internal NIC IP - 10.0.0.102/8

## use vagrant to install centos

file: Vagrantfile / script.sh



## Ansible Controller configuration


### 1.create script.sh
this script will do these things on all machines.  
1.Install epel-release and ansible.  
2.update /etc/hosts file  
3.open ssh terminal (like xshell and mobaxterm)login
```shell
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
```

### 2.create Vagrantfile
this Vagrantfile will bring up 4 virtual box machines.
```Vagrantfile
IMAGE_NAME = "centos/7"
N = 2

Vagrant.configure("2") do |config|
    config.ssh.insert_key = false

    config.vm.provider "virtualbox" do |v|
        v.memory = 2048
        v.cpus = 2
    end

    config.vm.define "k8s-ansiblec" do |ansiblec|
        ansiblec.vm.box = IMAGE_NAME
        ansiblec.vm.network "private_network", ip: "10.0.0.99"
        ansiblec.vm.hostname = "ansible.example.com"
        ansiblec.vm.provision "shell", path: "script.sh"
    end

    config.vm.define "k8s-master" do |master|
        master.vm.box = IMAGE_NAME
        master.vm.network "private_network", ip: "10.0.0.100"
        master.vm.hostname = "master.example.com"
        master.vm.provision "shell", path: "script.sh"
    end

    config.vm.define "nodeone" do |node|
        node.vm.box = IMAGE_NAME
        node.vm.network "private_network", ip: "10.0.0.101"
        node.vm.hostname = "nodeone.example.com"
        node.vm.provision "shell", path: "script.sh"
    end

    config.vm.define "nodetwo" do |node|
        node.vm.box = IMAGE_NAME
        node.vm.network "private_network", ip: "10.0.0.102"
        node.vm.hostname = "nodetwo.example.com"
        node.vm.provision "shell", path: "script.sh"
    end
end
```
use command: vagrant up

### 2.generate ssh keys on Ansible Controller and copy ssh key to master/nodeone/nodetwo
If everything is right . You must be able to ssh to all machines from Ansible machine ,without password .

```bash
ssh-keygen
cd /root/.ssh/
ssh-copy-id root@master.example.com
ssh-copy-id root@nodeone.example.com
ssh-copy-id root@nodetwo.example.com

ssh master.example.com  
exit  
ssh nodeone.example.com  
exit  
ssh nodetwo.example.com  
exit  
```

### 3.On ansible.example.com. Install git and download the ansible playbooks   
required for this setup from our git repository.
```bash
# mkdir -p  /root/ansible-k8s-setup
# cd /root/ansible-k8s-setup
```
then upload file ansible.cfg/hosts/k8s-master.yml/k8s-pkg.yml/k8s-workers.yml to dir /root/ansible-k8s-setup  


hosts  
```shell
[masters]
master.example.com
[workers]
nodeone.example.com
nodetwo.example.com
```

ansible.cfg
```shell
[defaults]
inventory      = /root/ansible-k8s-setup/hosts
[inventory]
[privilege_escalation]
[paramiko_connection]
[ssh_connection]
[persistent_connection]
[accelerate]
[selinux]
[colors]
[diff]
```

k8s-pkg.yml  
```yaml
- hosts: all
  become: yes
  tasks:

    - name: disable firewall service for labs
      service:
        name: firewalld
        state: stopped
        enabled: false

    - name: Disable SWAP
      shell: |
        swapoff -a

    - name: Disable SWAP in fstab
      lineinfile:
        path: /etc/fstab
        regexp: 'swap'
        state: absent

    - name: install Docker
      yum:
        name: docker
        state: present
        update_cache: true

    - name: start Docker
      service:
        name: docker
        state: started
        enabled: true

    - name: disable SELinux
      command: setenforce 0
      ignore_errors: yes

    - name: disable SELinux on reboot
      selinux:
        state: disabled

    - name: ensure net.bridge.bridge-nf-call-ip6tables is set to 1
      sysctl:
        name: net.bridge.bridge-nf-call-ip6tables
        value: 1
        state: present

    - name: ensure net.bridge.bridge-nf-call-iptables is set to 1
      sysctl:
        name: net.bridge.bridge-nf-call-iptables
        value: 1
        state: present

    - name: add Kubernetes YUM repository
      yum_repository:
        name: Kubernetes
        description: Kubernetes YUM repository
        baseurl: https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64
        gpgkey: https://packages.cloud.google.com/yum/doc/yum-key.gpg https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
        gpgcheck: yes

    - name: install kubelet
      yum:
        name: kubelet-1.14.0
        state: present
        update_cache: true

    - name: install kubeadm
      yum:
        name: kubeadm-1.14.0
        state: present

    - name: start kubelet
      service:
        name: kubelet
        enabled: yes
        state: started

- hosts: masters
  become: yes
  tasks:
    - name: install kubectl
      yum:
        name: kubectl-1.14.0
        state: present
        allow_downgrade: yes

- hosts: all
  become: yes
  tasks:
    - name: reboot ALL machines
      reboot:
```
k8s-master.yml
```yaml
- hosts: masters
  become: yes
  tasks:
    - name: initialize K8S cluster
      shell: kubeadm init --pod-network-cidr=172.16.0.0/16 --apiserver-advertise-address=10.0.0.100

    - name: create .kube directory
      file:
        path: $HOME/.kube
        state: directory
        mode: 0755

    - name: copy admin.conf to user kube config
      copy:
        src: /etc/kubernetes/admin.conf
        dest: /root/.kube/config
        remote_src: yes

    - name: install Pod network
      become: yes
      shell: kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/a70459be0084506e4ec919aa1c114638878db11b/Documentation/kube-flannel.yml >> pod_network_setup.txt
      args:
        chdir: $HOME
        creates: pod_network_setup.txt
```

k8s-workers.yml  
```yaml
- hosts: master.example.com
  become: yes
  gather_facts: false
  tasks:
    - name: get join command
      shell: kubeadm token create --print-join-command
      register: join_command_raw

    - name: set join command
      set_fact:
        join_command: "{{ join_command_raw.stdout_lines[0] }}"


- hosts: workers
  become: yes
  tasks:
    - name: join cluster
      shell: "{{ hostvars['master.example.com'].join_command }} --ignore-preflight-errors all  >> node_joined.txt"
      args:
        chdir: $HOME
        creates: node_joined.txt
```

### 4.ansible-playbook

On ansible.example.com.   
First run the k8s-pkg.yml playbook  
This playbook will do these tasks on all machines.  
1.Disable firewalld.  
2.Disable Swap and remove entry from /etc/fstab.  
3.Disable SELinux and update /etc/selinux/config file.  
4.Enable Bridging using sysctl.  
5.Install Docker and start docker service.  
6.Add kubernetes repository.  
7.Install kubelet and kubeadm.  
8.Start kubelet service.  
9.When everything is done, "reboot" all machines.
```bash
# ansible-playbook k8s-pkg.yml --syntax-check
# ansible-playbook k8s-pkg.yml
```
On ansible.example.com. Now run the "k8s-master.yml" file  
This playbook will do these tasks:  
1.Initialize kubernetes cluster with custom pod network and  
your server internal IP as communication IP.  
2.Copy the admin.conf to user's home directory.  
3.Install overlay network - flannel.  
```bash
# ansible-playbook k8s-master.yml --syntax-check
# ansible-playbook k8s-master.yml 
```

On "ansible.example.com". Now run "k8s-workers.yml".  
Thisplaybook will do these tasks:  
1.Create token for workers to join the cluster.  
2.Run the join command on all workers in our cluster. 
```bash
# ansible-playbook k8s-workers.yml --syntax-check
# ansible-playbook k8s-workers.yml
```

 