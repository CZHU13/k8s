安装Virtual box  
安装Vagrant  

box地址  
https://app.vagrantup.com/boxes/search  

1. 基础命令
- box列表  
vagrant box list

- 添加box  
vagrant box add centos/7

- 会生成一个Vagrantfile文件  
vagrant init centos/7

- 通过vagrantfile启动虚拟机  
vagrant up

- 连接到虚拟机  
vagrant ssh 虚拟机名称

- 查看虚拟机状态  
vagrant status

- 关机/开机 暂停、恢复 reload  
vagrant halt/up suspend/resume reload

- 删除虚拟机  
vagrant destroy

2. synced folder  
在默认情况下，vagrant会共享我们的项目目录  
在虚拟机里面会有一个目录/vagrant 和我们的项目目录是同步的。  

```Vagrantfile
config vm synced folder
config.vm.synced_folder "data", "/vagrant_data",
  create: true, owner: "root", group: "root"
```

3. networking  

3.1. forwarded_port 端口转发  
```Vagrantfile
config.vm.network "forwarded_port", guest: 80, host: 8080
在本机的local:8080 会转发到虚拟机的 80端口
```

3.2. private_network （可以理解为HostOnly）  
```Vagrantfile
config.vm.network "private_network", ip: "192.168.33.10"
```
3.3. public_network (可以理解为桥接模式)
networking : 
config.vm.network "public_network"

notice: NAT网卡是自动创建的。

4. package  
```Vagrantfile
vagrant package.box
vagrant box add my/centos7 package.box
vagrant box remove my/centos7
```

5. multi-machine
```bash
# -*- mode: ruby -*-
# vi: set ft=ruby :

# All Vagrant configuration is done below. The "2" in Vagrant.configure
# configures the configuration version (we support older styles for
# backwards compatibility). Please don't change it unless you know what
# you're doing.
Vagrant.configure("2") do |config|
  config.vm.box = "centos/7"
  config.vm.box_check_update = false
  config.vm.define "development" do |dev|
    dev.vm.network "private_network", ip: "192.168.33.10"
    dev.vm.hostname = "dev"
    dev.vm.synced_folder "dev", "/vagrant"
  end
  config.vm.define "production" do |prod|
    prod.vm.network "private_network", ip: "192.168.33.11"
    prod.vm.hostname = "prod"
    dev.vm.synced_folder "prod", "/vagrant"
  end
end
```