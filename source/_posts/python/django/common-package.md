---
title: Django | 通用的开发包
tags:
  - Django
categories:
  - - 后端
  - - Python
description: Django 项目中常用的第三方包
abbrlink: 51719
date: 2015-07-10 11:13:49
---

更新时间：2019-12-20 22:05:03

基于 `Django` 项目，通用的第三方开发工具包，这里只列出了通用的开发包，也包含了部分业务包，其他常见的涉及到具体的业务包，不再一一列出。

#### 1 DjangoRestFramework

<https://www.django-rest-framework.org/>

开发 `Restful` 接口的主力工具

#### 2 django-cors-headers

<https://github.com/adamchainz/django-cors-headers>

解决前后端分离接口请求跨域

#### 3 django-extensions

<https://github.com/django-extensions/django-extensions>

`Django` 扩展增强工具

#### 4 ipython

<https://ipython.org/>

强大的交互式 `shell`，测试调试非常顺手，当然不仅仅限于 `Django` 开发

#### 5 django-environ

<https://github.com/joke2k/django-environ>

区分各种环境的配置利器

#### 6 celery

<https://github.com/celery/celery>

分布式的任务队列分发器

#### 7 wechatpy

<https://github.com/wechatpy/wechatpy>

微信开发必备的 SDK

#### 8 gunicorn

<https://gunicorn.org/>

`Python WSGI HTTP Server`

#### 9 factory-boy

<https://github.com/FactoryBoy/factory_boy>

测试数据生成工具

#### 10 parameterized

<https://github.com/wolever/parameterized>

为测试用例提供参数化的，重复性支持

#### 11 pytest

<https://docs.pytest.org/en/latest/>

强大的第三方测试框架，丰富的插件集，活跃的社区

当然还有 `nose` 和 它的继任者 `nose2`，不过相比较而言，还是更加青睐于 `pytest`

`nose`：<https://nose.readthedocs.io/en/latest/>
`nose2`：<https://github.com/nose-devs/nose2>

不过 `nose` 已经不再更新，进入了维护阶段，如果使用建议使用 `nose2`

#### 12 raven

<https://raven.readthedocs.io/en/feature-federated-docs/>

这个一般都是结合 `Sentry` 使用

#### 13 mysqlclient

<https://github.com/PyMySQL/mysqlclient-python>

因为我使用 `Mysql` 较多

#### 14 django-silk

<https://github.com/jazzband/django-silk>

简单的性能监控工具

#### 15 django-debug-toolbar

<https://github.com/jazzband/django-debug-toolbar>

`debug` 工具

#### 16 django-reversion

<https://github.com/etianen/django-reversion>

模型版本控制

#### 17 whitenoise

<https://github.com/evansd/whitenoise>

静态资源管理，通常是用来管理 `django admin` 和其他第三方包的静态资源。

#### 18 django-sql-explorer

<https://github.com/groveco/django-sql-explorer>

`SQL` 运行查询辅助工具

#### 19 django-import-export

<https://github.com/django-import-export/django-import-export>

数据导入导出

#### 20 django-compressor

<https://django-compressor.readthedocs.io/en/stable/>

合并静态资源，减少网络请求，一般使用在 `django admin` 中。
