---
title: Linux 不同的发行版设置静态 IP
tags:
  - Debian
categories:
  - Linux
abbrlink: 29624
date: 2020-10-16 22:01:37
---

近来在折腾本地服务器，为了方式每次重启 IP 地址的变化，所以要给机器设置静态 IP <!--more-->

## 一 不同发行版静态 IP 设置

### 1 Centos 设置静态 IP

#### 1.1 找出需要设置静态 IP 的网络接口名称

```shell
[isproot@192 ~]$ nmcli device status
DEVICE      TYPE      STATE      CONNECTION
eth192        ethernet  connected  System eth192
virbr0      bridge    connected  virbr0
lo          loopback  unmanaged  --
virbr0-nic  tun       unmanaged  --
```

可以看到需要设置的接口对应的名称是 `eth192`

#### 1.2 修改网络接口相关的配置文件

该文件通常位于 `/etc/sysconfig/network-scripts/` 目录下，文件名格式为 `ifcfg-<接口名称>`。例如，如果接口名称为 ens33，需要编辑 /etc/sysconfig/network-scripts/ifcfg-ens33 文件。使用以下命令打开文件：

```
vi /etc/sysconfig/network-scripts/ifcfg-eth192
```

然后做以下改动

1. 找到 `BOOTPROTO=dhcp` 行，将 `dhcp` 更改为 `static` 或 `none`
2. 在文件末尾添加以下行

```python
# 静态 IP
IPADDR=192.168.1.12
# 默认网关
GATEWAY=192.168.1.1
```

修改后文件如下：

```python
TYPE=Ethernet
PROXY_METHOD=none
BROWSER_ONLY=no
# 这里可以使用 static 或者 no
BOOTPROTO=none
DEFROUTE=yes
IPV4_FAILURE_FATAL=no
IPV6INIT=yes
IPV6_AUTOCONF=yes
IPV6_DEFROUTE=yes
IPV6_FAILURE_FATAL=no
IPV6_ADDR_GEN_MODE=stable-privacy
NAME=ens192
UUID=cd93f1df-d2d5-4c63-a64c-761e9ee23aae
DEVICE=ens192
# 开机启用此配置
ONBOOT=yes
# 静态 IP
IPADDR=192.168.1.12
# 默认网关
GATEWAY=192.168.1.1
```

#### 1.3 重启网络服务

对于 `Centos7`:

```
systemctl restart network
```

对于 `Centos8`:

```
systemctl restart NetworkManager
```

#### 1.4 查看地址

```shell
[isproot@192 ~]$ ip addr
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host
       valid_lft forever preferred_lft forever
2: ens192: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast state UP group default qlen 1000
    link/ether 00:0c:29:51:63:21 brd ff:ff:ff:ff:ff:ff
    inet 192.168.1.12/24 brd 192.168.1.255 scope global noprefixroute ens192
       valid_lft forever preferred_lft forever
    inet6 2408:8256:a80:313:6ba6:7ad0:edd0:defe/64 scope global noprefixroute dynamic
       valid_lft 183241sec preferred_lft 96841sec
    inet6 fe80::b6f3:1daa:4b7b:6994/64 scope link noprefixroute
       valid_lft forever preferred_lft forever
```

现在，CentOS 系统应该使用指定的静态 IP 地址进行网络通信。请注意，为了避免 IP 地址冲突，您需要确保分配给 CentOS 系统的静态 IP 地址在本地网络中是唯一的，并且不在 DHCP 服务器的分配范围内

### 2 Debian 设置静态 IP

#### 2.1 找出需要设置静态 IP 的网络接口名称

```shell
root@debian:~# ip addr
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host
       valid_lft forever preferred_lft forever
2: ens192: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc mq state UP group default qlen 1000
    link/ether 00:0c:29:92:2d:16 brd ff:ff:ff:ff:ff:ff
    inet 192.168.1.103/24 brd 192.168.1.255 scope global noprefixroute ens192
       valid_lft forever preferred_lft forever
    inet6 fe80::6c5d:abfc:8b6:bd5c/64 scope link noprefixroute
       valid_lft forever preferred_lft forever
```

将看到类似于 eth0、enp0s3 或 enp192 等的接口名称。请记下要设置静态 IP 的接口名称，这里需要调整的接口即为 `eth192`

#### 2.2 修改网络配置

```shell
vi /etc/network/interfaces
```

在文件中找到您要设置静态 IP 的接口。它应该类似于以下内容：

```python
iface eth192 inet dhcp
```

其中 `eth192` 是网络接口的名称，`dhcp` 表示该接口使用 `DHCP` 获取 IP 地址。

将 `dhcp` 更改为 `static`，然后添加 `address`、`netmask`、`gateway` 和 `dns-nameservers` 参数。例如：

```python
iface eth0 inet static
    address 192.168.1.11
    netmask 255.255.255.0
    gateway 192.168.1.1
    dns-nameservers 8.8.8.8 8.8.4.4
```

确保使用适当的 IP 地址、子网掩码、网关和 DNS 服务器替换上述示例中的值。

修改后文件如下

```shell
# This file describes the network interfaces available on your system
# and how to activate them. For more information, see interfaces(5).

source /etc/network/interfaces.d/*

# The loopback network interface
auto lo
iface lo inet loopback

# The primary network interface
allow-hotplug ens192
# iface ens192 inet dhcp
# 设置成静态 IP
iface ens192 inet static
# 设置 IP
address 192.168.1.11
# 设置子网掩码
netmask 255.255.255.0
# 设置网关
gateway 192.168.1.1
# 设置 DNS 服务器，我这里设置成路由器的地址
dns-nameservers 192.168.1.1
# This is an autoconfigured IPv6 interface
iface ens192 inet6 auto
```

#### 2.3 重启网络服务

```
service networking restart
```

#### 2.4 查看地址

```shell
root@debian:~# ip addr
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host
       valid_lft forever preferred_lft forever
2: ens192: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc mq state UP group default qlen 1000
    link/ether 00:0c:29:0a:14:07 brd ff:ff:ff:ff:ff:ff
    inet 192.168.1.11/24 brd 192.168.1.255 scope global ens192
       valid_lft forever preferred_lft forever
    inet6 2408:8256:a81:c14f:20c:29ff:fe0a:1407/64 scope global dynamic mngtmpaddr
       valid_lft 206755sec preferred_lft 120355sec
    inet6 fe80::20c:29ff:fe0a:1407/64 scope link
       valid_lft forever preferred_lft forever
```

## 二 小结

从配置的过程来看，基本上都是配置文件的目录和配置项不同而已，其他基本上都差不多，毕竟原理都是一样的。
