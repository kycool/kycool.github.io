---
title: Mac-解锁网易云置灰音乐
tags:
  - Mac
categories:
  - - 危险边缘
abbrlink: 41185
date: 2020-09-08 23:51:35
---

我的网易云黑胶会员 VIP 到期了，暂时不想续期，找了个法子解锁置灰的歌，后面再想想续期的事情。解锁的原理比较简单，劫持网易云音乐客户端的请求，打到代理服务中去，代理服务会自动解析，如果有些歌听不了，会自动请求其他音源进行替换，这个大家都懂的。下面记录下步骤。<!--more-->

工具和对应的版本：

- 网易云音乐 for mac：2.0.0 (690) 下载地址：http://d1.music.126.net/dmusic/NeteaseMusic_2.0.0_690_web.dmg
- mac: 10.15.5 (19F101)
- node: v10.16.3
- Proxifier for mac: v2.26 下载地址: https://xclient.info/s/proxifier.html

### 1 下载解锁项目

Github：https://github.com/nondanee/UnblockNeteaseMusic

这里照着文档克隆，然后双击安装其中的 ca.crt 并设置信任。因为后面要跑服务，新建了 m.sh 并赋予可执行的权限，直接用 m.sh 代码如下

```shell
#!/bin/bash

pattern='[(].*[)]'
# 注意这里改成自己的目录地址
path=~/Documents/githubpro/UnblockNeteaseMusic/app.js

# 这里是获取 music.163.com 的 IP 地址
ip=`ping music.163.com -c 1 | grep -o $pattern`
ip=${ip:1}
ip=${ip%?}

# 这里的端口号自己可以调整
sudo node app.js -p 63455:7777 -f $ip
```

然后在包含 m.sh 的目录下执行 m.sh

```shell
$ ./m.sh

HTTP Server running @ http://0.0.0.0:63455
HTTPS Server running @ http://0.0.0.0:7777
```

注意：ping music.163.com 出来的 IP 地址有可能是变化的，so 如果歌听不了，重新运行服务即可。

### 2 代理设置

因为网易云 mac 的客户端没有可以设置代理的地方，有些傲娇，那就使用 Proxifier 来解决吧。

2.1 添加 Proxies，地址写 127.0.0.1 端口对应上面，为 63455
2.2 添加 Rules

```python
Applications 为 NeteaseMusic;com.apple.WebKit.Networking

Target Hosts 为 *.music.163.com;*.music.126.net;*.netease.com;music.163.com;interface.music.163.com

Action 为上面创建的，即 Proxy HTTPS 127.0.0.1:63455
```

2.3 DNS 配置
在 Resolve hostnames through proxy 前面打勾

好了，代理配置好了。

### 3 重启网易云音乐

搜索 JAY 的歌，之前置灰的歌可以播放了，例如听以父之名，日志如下：

```shell
TUNNEL > localhost:63455
MITM > music.163.com
MITM > music.163.com
[1400394244] 以父之名 (Live)
http://sz.sycdn.kuwo.cn/cadd34fd7d42d643db5257b182f07ad5/5f57a6b9/resource/n1/69/17/1415834243.mp3
MITM > music.163.com
```

使用这种方式听歌呢，因为要跑服务和代理，so 最好还是用脚本打开网易云音乐，省事。
