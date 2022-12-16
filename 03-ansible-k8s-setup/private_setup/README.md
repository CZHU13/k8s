Youtube address: 
https://www.youtube.com/watch?v=SrhmT-zzoeA  

official reference : 
https://kubernetes.io/blog/2019/03/15/kubernetes-setup-using-ansible-and-vagrant/




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


## Ansible Controller configuration


### 1.Install epel-release repository. Repeat on all machines.

```bash
yum -y install epel-release
yum -y install ansible
```

### 2.Check /etc/hosts and hostname
```bash
# vi /etc/hosts
127.0.0.1  localhost localhost.localdomain localhost4 localhost4.localdomain4
::1        localhost localhost.localdomain localhost6 localhost6.localdomain6
10.0.0.99  ansible.example.com ansible
10.0.0.100 master.example.com master
10.0.0.101   nodeone.example.com nodeone
10.0.0.102   nodetwo.example.com nodetwo

# hostname
ansible.example.com

# scp /etc/hosts root@10.0.0.100:/etc
# scp /etc/hosts root@10.0.0.101:/etc
# scp /etc/hosts root@10.0.0.102:/etc
```


### 3.generate ssh keys on Ansible Controller and copy ssh key to master/nodeone/nodetwo
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

### 4.On ansible.example.com. Install git and download the ansible playbooks   
required for this setup from our git repository.
```bash
# yum -y install git  
# git clone https://github.com/networknuts/ansible-k8s-setup.git  
# cd ansible-k8s-setup
```
### 5.ansible-playbook
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
```
On ansible.example.com. Now run the "k8s-master.yml" file  
This playbook will do these tasks:  
1.Initialize kubernetes cluster with custom pod network and  
your server internal IP as communication IP.  
2.Copy the admin.conf to user's home directory.  
3.Install overlay network - flannel.  
```bash
# ansible-playbook k8s-master.yml --syntax-check
```

On "ansible.example.com". Now run "k8s-workers.yml".  
Thisplaybook will do these tasks:  
1.Create token for workers to join the cluster.  
2.Run the join command on all workers in our cluster. 
```bash
# ansible-playbook k8s-workers.yml --syntax-check
```

 