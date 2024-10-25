---
title: 本地开发使用 https
tags:
  - https
categories:
  - - 开发工具
abbrlink: 32953
date: 2019-04-05 23:41:41
---

这阵子本地开发测试，需要本地可以使用 HTTPS 证书，找到了 `mkcert` 这个傻瓜式的工具（<https://github.com/FiloSottile/mkcert>),

mkcert 设计很简单，优雅，隐藏了几乎所有生成 TLS 证书所必须的知识，它适用于任何域名，主机名，IP，包括 localhost，但是切记，只能在本地使用。<!--more-->

证书是由你自己的私有 CA 签发，当你运行 `mkcert-install` 会自动配置这些信任，因此，当浏览器访问时，就会显示安全标识。

与 OpenSSL 不同的是，不需要为每个证书配置很多选项。mkcert 最主要的功能是作为开发者工具，聚焦于让本地环境配置 TLS 证书变得简单高效。

### 1 安装

```shell
brew install mkcert
brew install nss # if you use Firefox
```

### 2 使用

您需要首先在系统信任库中安装本地 CA.

```shell
$ mkcert -install

Using the local CA at "/Users/kycool/Library/Application Support/mkcert" ✨
The local CA is already installed in the system trust store! 👍
```

完成后，可以给自己的本地域名生成证书了，生成证书很简单

```shell
$ sudo mkcert kycooltest.cn '*.kycooltest.cn' localhost 127.0.0.1 ::1
Using the local CA at "/Users/kycool/Library/Application Support/mkcert" ✨

Created a new certificate valid for the following names 📜
 - "kycooltest.cn"
 - "*.kycooltest.cn"
 - "localhost"
 - "127.0.0.1"
 - "::1"

Reminder: X.509 wildcards only go one level deep, so this won't match a.b.kycooltest.cn ℹ️

The certificate is at "./kycooltest.cn+4.pem" and the key at "./kycooltest.cn+4-key.pem" ✅
```

### 3 验证

添加本地 `hosts` 记录

```python
127.0.0.1 kycooltest.cn
```

添加 nginx 配置文件

```python
server {
    listen *:443 ssl;
    server_name  kycooltest.cn;

    root /var/www;

    ssl_certificate /Users/kycool/Documents/caddy/kycooltest.cn+4.pem;
    ssl_certificate_key /Users/kycool/Documents/caddy/kycooltest.cn+4-key.pem;
}
```

接着在 浏览器中打开 `https://kycooltest.cn`

![mkcert.png](mkcert.png)
