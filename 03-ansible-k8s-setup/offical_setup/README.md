Address : https://kubernetes.io/blog/2019/03/15/kubernetes-setup-using-ansible-and-vagrant/

# Kubernetes Setup Using Ansible and Vagrant

## Objective  
This blog post describes the steps required to setup a multi node Kubernetes cluster  
for development purposes. This setup provides a production-like cluster that can be  
setup on your local machine.
这篇博文描述了设置多节点 Kubernetes 集群所需的步骤
用于开发目的。 此设置提供了一个类似生产的集群，可以
在本地机器上设置。

## Why use Vagrant and Ansible?
Vagrant is a tool that will allow us to create a virtual environment easily and it  
eliminates pitfalls that cause the works-on-my-machine phenomenon. It can be used  
with multiple providers such as Oracle VirtualBox, VMware, Docker, and so on. It  
allows us to create a disposable environment by making use of configuration files.  
<br>
Vagrant 是一个可以让我们轻松创建虚拟环境的工具，它
消除了导致“在我的机器上工作”现象的陷阱。 可以用
与多个供应商合作，例如 Oracle VirtualBox、VMware、Docker 等。 它
允许我们通过使用配置文件来创建一次性环境。 

Ansible is an infrastructure automation engine that automates software configuration  
management. It is agentless and allows us to use SSH keys for connecting to remote  
machines. Ansible playbooks are written in yaml and offer inventory management in simple  
text files.  
<br>
Ansible 是一种基础架构自动化引擎，可自动执行软件配置
管理。 它是无代理的，允许我们使用 SSH 密钥连接到远程
机器。 Ansible 剧本是用 yaml 编写的，并以简单的方式提供库存管理
文本文件。

### Prerequisites

- Vagrant should be installed on your machine. Installation binaries can be found [here][1]. 
- Oracle VirtualBox can be used as a Vagrant provider or make use of similar providers  
  as described in Vagrant's official [documentation][2].
- Ansible should be installed in your machine. Refer to the [Ansible installation guide ][3]
  for platform specific installation.
- Vagrant 应该安装在你的机器上。 安装二进制文件可以在这里找到。
- Oracle VirtualBox 可以用作 Vagrant 提供者或使用类似的提供者
   如 Vagrant 的官方文档中所述。
- Ansible 应该安装在你的机器上。 参考 Ansible 安装指南
   用于特定于平台的安装。

## Setup overview 
We will be setting up a Kubernetes cluster that will consist of one master and two worker  
nodes. All the nodes will run Ubuntu Xenial 64-bit OS and Ansible playbooks will be used  
for provisioning.

我们将建立一个 Kubernetes 集群，该集群将由一个主节点和两个 worker 组成
节点。 所有节点都将运行 Ubuntu Xenial 64 位操作系统，并且将使用 Ansible playbooks
用于配置。

### Step 1: Creating a Vagrantfile
Use the text editor of your choice and create a file with named Vagrantfile, inserting  
the code below. The value of N denotes the number of nodes present in the cluster, it  
can be modified accordingly. In the below example, we are setting the value of N as 2.  
使用您选择的文本编辑器并创建一个名为 Vagrantfile 的文件，插入
下面的代码。 N 的值表示集群中存在的节点数，它
可以相应修改。 在下面的示例中，我们将 N 的值设置为 2。 

```ruby
IMAGE_NAME = "bento/ubuntu-16.04"
N = 2

Vagrant.configure("2") do |config|
    config.ssh.insert_key = false

    config.vm.provider "virtualbox" do |v|
        v.memory = 1024
        v.cpus = 2
    end
      
    config.vm.define "k8s-master" do |master|
        master.vm.box = IMAGE_NAME
        master.vm.network "private_network", ip: "192.168.50.10"
        master.vm.hostname = "k8s-master"
        master.vm.provision "ansible" do |ansible|
            ansible.playbook = "kubernetes-setup/master-playbook.yml"
            ansible.extra_vars = {
                node_ip: "192.168.50.10",
            }
        end
    end

    (1..N).each do |i|
        config.vm.define "node-#{i}" do |node|
            node.vm.box = IMAGE_NAME
            node.vm.network "private_network", ip: "192.168.50.#{i + 10}"
            node.vm.hostname = "node-#{i}"
            node.vm.provision "ansible" do |ansible|
                ansible.playbook = "kubernetes-setup/node-playbook.yml"
                ansible.extra_vars = {
                    node_ip: "192.168.50.#{i + 10}",
                }
            end
        end
    end
end
```

### Step 2: Create an Ansible playbook for Kubernetes master. 
Create a directory named kubernetes-setup in the same directory as the Vagrantfile. 
Create two files named master-playbook.yml and node-playbook.yml in the directory 
kubernetes-setup.

In the file master-playbook.yml, add the code below.

[1]: https://www.vagrantup.com/downloads.html
[2]: https://www.vagrantup.com/docs/providers/
[3]: https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html