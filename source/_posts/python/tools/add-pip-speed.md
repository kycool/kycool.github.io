---
title: 资源加速系列之 pip
tags:
  - 镜像
  - 加速
categories:
  - - 后端
  - - Python
  - - 资源加速
abbrlink: 26327
date: 2015-09-01 11:06:51
---

在 `python` 项目中，安装包时，都会从官方默认的源：<!--more-->

```
https://pypi.org/simple
```

中下载，速度较慢，原因不多说了，针对这个情况，国内有些公司和机构做了镜像站，以便国内的用户提高下载速度。

<!--more-->

### 1 国内的镜像源列表

列举几个常用的，少用的就不列了

- https://mirrors.aliyun.com/pypi/simple/ 阿里云
- https://pypi.tuna.tsinghua.edu.cn/simple/ 清华大学
- https://pypi.doubanio.com/simple/ 豆瓣
- https://mirrors.ustc.edu.cn/pypi/web/simple/ 中国科学技术大学

上面的源站都测试过，对我来说，首选阿里云，因为确实快

### 2 临时指定镜像源

```
pip install -i 镜像源地址 包名称
```

例如安装 `django`，选用阿里云镜像源，则

```
pip install -i https://mirrors.aliyun.com/pypi/simple/ django
```

### 3 全局设置镜像源

我个人使用的是 mac，步骤：

1 在用户主目录下 `~/.config` 中新建 `pip` 文件夹（也可以直接在用户主目录下建立 `.pip` 文件夹)

2 在上一步新建的文件中新建 `pip.conf`

3 在 `pip.conf` 文件中添加以下配置

```python
[global]
timeout = 60
index-url = https://mirrors.aliyun.com/pypi/simple

[install]
trusted-host=mirrors.aliyun.com
```

可以阅览官方文档：https://pip.pypa.io/en/stable/user_guide/#config-file

```
You can set a custom path location for this config
file using the environment variable PIP_CONFIG_FILE.
```

用户可以自定义配置文件路径，配置好环境变量 `PIP_CONFIG_FILE` 即可。

后续再安装 `python` 包都会使用设置好的源，节省时间。
