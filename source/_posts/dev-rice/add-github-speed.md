---
title: 资源加速系列之 Github
reward: true
tags:
  - 加速
categories:
  - - 资源加速
abbrlink: 19128
date: 2020-03-18 10:50:20
---

### 1 故事发生背景

这段时间，github 的 clone 快搞死人了，速度慢的一逼，上网看了几种方法<!--more-->

1. 改 hosts（亲测差异不大）
2. 先拉到 gitee，再从 gitee 克隆
3. 走代理

我使用了代理，第二种方法不适合我，为什么，一个是自己懒，另外一个就是安装某些软件，这些软件特么的自己写死了 clone 地址（一般都是不能改的），所以果断抛弃，直奔第三种方式

### 2 执行方法

**走代理，你特么的需要个梯子呀**

我使用的是 ss 服务，看图说话

![ssproxy.png](addGithubSpeed_ssproxy.png)

很清晰，没毛病，然后进行下一步

不同的协议他的代理配置各不相同

- `core.gitproxy`  用于  `git://`  协议
- `http.proxy`  用于  `http://`  协议
- `https.proxy`  用于  `https://`  协议

全局设置 git 的配置

```
# 这里是针对 http 和 https 协议的
git config --global http.proxy 'socks5://127.0.0.1:1086'
git config --global https.proxy 'socks5://127.0.0.1:1086'

# 这里是针对 git 协议的
git config --global core.gitproxy "git-proxy"
git config --global socks.proxy 'socks5://127.0.0.1:1086'
```

设置完后，看下 git 的全局配置 `git config --global --list`

```python
user.name=xxxx
user.email=xxxxx@gmail.com
core.excludesfile=/Users/kycool/.gitignore_global
core.gitproxy=git-proxy
difftool.sourcetree.cmd=opendiff "$LOCAL" "$REMOTE"
difftool.sourcetree.path=
mergetool.sourcetree.cmd=/Applications/Sourcetree.app/Contents/Resources/opendiff-w.sh "$LOCAL" "$REMOTE" -ancestor "$BASE" -merge "$MERGED"
mergetool.sourcetree.trustexitcode=true
commit.template=/Users/kycool/.stCommitMsg
http.proxy=socks5://127.0.0.1:1086
https.proxy=socks5://127.0.0.1:1086
socks.proxy=socks5://127.0.0.1:1086
```

如果后面想删掉这些配置，则可以执行以下命令

```python
git config --global --unset 键
```

添加 ssh 配置，在 `.ssh/config` 文件中添加

```python
Host github.com
HostName github.com
User git
port 22
UseKeychain yes
IdentityFile /Users/kycool/.ssh/id_rsa
ProxyCommand nc -v -x 127.0.0.1:1086 %h %p
```

好了，到享受的时候了，我测试了 git 协议和 https 协议

### 3 克隆测试

**git 协议**: clone antd-pro

```python
$ git clone git@github.com:ant-design/ant-design-pro.git
Cloning into 'ant-design-pro'...
remote: Enumerating objects: 31, done.
remote: Counting objects: 100% (31/31), done.
remote: Compressing objects: 100% (29/29), done.
remote: Total 18085 (delta 9), reused 14 (delta 2), pack-reused 18054
Receiving objects: 100% (18085/18085), 6.02 MiB | 299.00 KiB/s, done.
Resolving deltas: 100% (12239/12239), done.
```

从来没有见过的速度，几乎是秒杀

**https 协议**: hexo init mm

```python
$ hexo init mm
INFO  Cloning hexo-starter https://github.com/hexojs/hexo-starter.git
Cloning into '/Users/kycool/Documents/test/mm'...
remote: Enumerating objects: 30, done.
remote: Counting objects: 100% (30/30), done.
remote: Compressing objects: 100% (24/24), done.
remote: Total 161 (delta 12), reused 12 (delta 4), pack-reused 131
Receiving objects: 100% (161/161), 31.79 KiB | 206.00 KiB/s, done.
Resolving deltas: 100% (74/74), done.
Submodule 'themes/landscape' (https://github.com/hexojs/hexo-theme-landscape.git) registered for path 'themes/landscape'
Cloning into '/Users/kycool/Documents/test/mm/themes/landscape'...
remote: Enumerating objects: 9, done.
remote: Counting objects: 100% (9/9), done.
remote: Compressing objects: 100% (9/9), done.
remote: Total 1063 (delta 1), reused 1 (delta 0), pack-reused 1054
Receiving objects: 100% (1063/1063), 3.22 MiB | 217.00 KiB/s, done.
Resolving deltas: 100% (582/582), done.
Submodule path 'themes/landscape': checked out '73a23c51f8487cfcd7c6deec96ccc7543960d350'
INFO  Install dependencies
```

速度和上面一个几乎不相上下。

测试的速度是不断变化的，我观察有瞬间跑到 600 KiB/s，我估摸着如果代理服务器的带宽牛逼的话，那速度想都不敢想。

### 4 不足的地方

这里面的哪一种方法都是有些不足的，梯子偶尔也会抽风，因为是我买的别人家的服务，这种保障不能主观控制，抽风就回到解放前了。
