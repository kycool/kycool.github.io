---
title: 资源加速系列之 pyenv
tags:
  - 镜像
  - 加速
categories:
  - - 后端
  - - Python
  - - 资源加速
abbrlink: 22631
date: 2016-10-22 00:05:26
---

对于 `python` 相关的业务，我都是使用 `pyenv`，来管理我本地的 `python` 版本，由于不同项目的需要，有些项目使用的 `python` 版本都是不一致，所以本地安装了不同的版本。<!--more-->

### 1 加速

刚开始装 `python`，都是执行 `pyenv install 版本号` 进行安装，但是发现速度，在国内，你懂得，太慢，所以就去找镜像，我使用了淘宝的镜像，地址如下

```
https://npm.taobao.org/mirrors/python/
```

其实加速就是从镜像地址把指定版本的 `python` 压缩包下载到 `~/.pyenv/cache` 下面，然后执行 `pyenv install 对应的版本号` 即可。

例如安装 3.6.7 版本，命令行如下

```
v=3.6.7;wget https://npm.taobao.org/mirrors/python/$v/Python-$v.tar.xz -P ~/.pyenv/cache/;pyenv install $v
```

### 2 做成可执行文件

我个人是有懒癌的，如果每次安装其他版本，都要这么执行，输入一长串，受不鸟，那就封装成 `shell` 脚本，脚本如下：

```bash
#!/bin/bash

function pyenvInstallPython()
{
    echo $1
    v=$1
    wget https://npm.taobao.org/mirrors/python/$v/Python-$v.tar.xz -P ~/.pyenv/cache/;pyenv install $v
}

pyenvInstallPython $*
```

然后把这个脚本写到可执行文件（我起的名字叫做 `pyversion`)中，然后把可执行文件移动到可执行目录中（即能在 `$PATH` 指定的路径中找到这个文件），我个人的做法，在我的用户目录建立了一个 `bin` 目录（加入到 `$PATH` 中去），然后把 `pyversion` 这个可执行文件移动到 `~/bin` 中去。

好了，可以了，后面想安装对应的版本，直接在终端中执行

```
pyversion 版本号
```

### 3 测试

例如我要装 3.6.7 版本，在终端执行 `pyversion 3.6.7`，执行结果：

```shell
3.6.7
--2016-10-22 01:16:10--  https://npm.taobao.org/mirrors/python/3.6.7/Python-3.6.7.tar.xz
正在解析主机 npm.taobao.org (npm.taobao.org)... 114.55.80.225
正在连接 npm.taobao.org (npm.taobao.org)|114.55.80.225|:443... 已连接。
已发出 HTTP 请求，正在等待回应... 302 Found
位置：https://cdn.npm.taobao.org/dist/python/3.6.7/Python-3.6.7.tar.xz [跟随至新的 URL]
--2016-10-22 01:16:10--  https://cdn.npm.taobao.org/dist/python/3.6.7/Python-3.6.7.tar.xz
正在解析主机 cdn.npm.taobao.org (cdn.npm.taobao.org)... 119.147.111.226, 119.147.111.229, 113.105.168.156, ...
正在连接 cdn.npm.taobao.org (cdn.npm.taobao.org)|119.147.111.226|:443... 已连接。
已发出 HTTP 请求，正在等待回应... 200 OK
长度：17178476 (16M) [application/x-xz]
正在保存至: “/Users/kycool/.pyenv/cache/Python-3.6.7.tar.xz”

Python-3.6.7.tar.xz              100%[========================================================>]  16.38M  8.36MB/s  用时 2.0s

2016-10-22 01:16:12 (8.36 MB/s) - 已保存 “/Users/kycool/.pyenv/cache/Python-3.6.7.tar.xz” [17178476/17178476])

python-build: use openssl@1.1 from homebrew
python-build: use readline from homebrew
Installing Python-3.6.7...
python-build: use readline from homebrew
python-build: use zlib from xcode sdk
Installed Python-3.6.7 to /Users/kycool/.pyenv/versions/3.6.7
```

速度果然是杠杠的，再输入 `pyenv versions` 看下

```
$ pyenv versions
* system (set by /Users/kycool/.pyenv/version)
  3.6.0
  3.6.7
```

可以，后续就可以这样玩了，省时省力。
