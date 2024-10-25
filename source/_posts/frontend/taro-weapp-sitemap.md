---
title: 微信小程序未找到入口 sitemap.json
tags:
  - Taro
  - 小程序
categories:
  - 前端
abbrlink: 6541
date: 2019-08-03 01:29:21
---

`Error`: 未找到入口 `sitemap.json` 文件，或者文件读取失败，请检查后重新编译

<!--more-->

### 1 问题描述

今天在微信开发者工具中发现了一个错误，这个错误一直没有注意到。

```
`Error`: 未找到入口 `sitemap.json` 文件，或者文件读取失败，请检查后重新编译
```

这个错误不会影响小程序的正常使用，查阅了文档（[微信小程序 sitemap.json](https://developers.weixin.qq.com/miniprogram/dev/reference/configuration/sitemap.html`)），才知道这个文件是用来给微信小程序搜索建立索引用的，下面再仔细分析下这个功能。

### 2 解决方法

第一步：我根据错误描述，在 app.jsx(我使用了 Taro) 同级目录下新建了一个 `sitemap.json` 文件，内容如下:

```json
{
  "rules": [
    {
      "action": "allow",
      "page": "*"
    }
  ]
}
```

第二步：接着在 `app.jsx` 中的 `config` 中添加

```
sitemapLocation: 'sitemap.json',
```

然后编译测试，发现还是出现同样的错误，然后发现 `dist` 文件夹下面没有 `sitemap.json` 文件，这个可能是 `Taro` 不支持的原因，但是 `Taro` 还是提供了一个 `copy` 的编译功能（[Taro 编译配置 copy](https://nervjs.github.io/taro/docs/config-detail.html#copy))，摘出来如下：

> copy

文件 `copy` 配置，包含两个配置项 `patterns` 和 `options`。

**copy.patterns**

用来指定需要拷贝的文件或者目录，数组类型，每一项都必须包含 `from` 、`to` 的配置，分别代表来源和需要拷贝到的目录，同时可以设置 `ignore` 配置来指定需要忽略的文件， `ignore` 是指定的 `glob` 类型字符串，或者 glob 字符串数组。

值得注意的是，目前 `from` 必须指定存在的文件或者目录，暂不支持 `glob` 格式， `from` 和 `to` 直接置顶项目根目录下的文件目录，建议 `from` 以 `src` 目录开头，`to` 以 `dist` 目录开头。

一般有如下的使用形式：

```
copy: {
    patterns: [
        { from: 'src/asset/tt/', to: 'dist/asset/tt/', ignore: '*.js' }, // 指定需要 copy 的目录
        { from: 'src/asset/tt/sd.jpg', to: 'dist/asset/tt/sd.jpg' } // 指定需要 copy 的文件
    ]
},
```

**copy.options**

拷贝配置，目前可以指定全局的 `ignore`：

```
copy: {
    options: {
        ignore: ['*.js', '*.css'] // 全局的 ignore
    }
}
```

第三步：好了，看完文档后，直接修改 `Taro` 的配置文件，添加以下内容：

```
copy: {
    patterns: [
        {
            from: 'src/sitemap.json',
            to: 'dist/sitemap.json'
        }
    ],
    options: {}
},
```

再次编译测试，正常，查看 `dist` 文件夹也存在 `sitemap.json` 文件。

### 3 聊下 sitemap

这个功能不错，增加小程序的曝光度，而且开发者还可以根据业务需要自定义被索引的页面，很实用。如果你不关心这些东西，就参考我的 `sitemap.json` 配置。
