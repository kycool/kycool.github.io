---
title: 前端 | 重构 gulpfile.js
tags:
  - Gulp
categories:
  - 前端
abbrlink: 18305
date: 2015-06-05 18:56:35
---

迭代持续重构 gulpfile.js<!--more-->

### 1 背景

前端任务打包工具选用的是 `gulp`, 当时选用 `gulp` 也是偶然，在使用 `grunt` 初期，翻阅 `dailyjs.com` 时发现一片文章着重介绍了 `gulp`, 甚至还预言是 `grunt` 的劲敌，好奇心驱使，确实发现，`gulp` 的流的概念更人性化，看着当时写的 `grunt` 配置文件，不忍直视 <!--more-->

由于项目的不断迭代，前端的任务也在不断的迭代，任务越来越多，没有优化前，全部的任务都在一个单独的 `gulpfile.js` 中，后来随着时间的推移，发现修改一个任务时，查询好麻烦，五百行左右的代码让人烦躁，代码结构和 <https://github.com/gulpjs/gulp/blob/master/docs/recipes/using-multiple-sources-in-one-task.md> 如出一辙

重构 `gulpfile.js` 必须要进行

### 2 重构迭代 1: 拆分任务

最先是按照 <https://github.com/gulpjs/gulp/blob/master/docs/recipes/split-tasks-across-multiple-files.md> 此文档中的架构进行迭代的

#### 文件结构

```javascript
    gulpfile.js
    tasks/
    ├── xxxx.js
    ├── xxxx.js
    └── image.js
```

#### image.js

```javascript
var imagemin = require("gulp-imagemin");

gulp.task("img", function () {
  return gulp
    .src("./images/**/*.*")
    .pipe(
      imagemin({
        optimizationLevel: 2,
        progressive: true,
      })
    )
    .pipe(gulp.dest("./imagemini"));
});
```

#### gulpfile.js

```javascript
var requireDir = require("require-dir"),
  tasks = requireDir("./tasks");
```

这种文件架构让任务按照类型分成子任务放在单独的文件中，顿时感觉干净了很多，这时可以自由的添加子任务，而不用管 `gulpfile.js`, 此时子任务好比插件，需要就添加，没用就删除，相当方便

### 3 重构迭代 2: 避免模块和插件重复依赖

随着时间的推移，发现这种组织架构还是有些不方便，不方便在哪里呢，每一个任务文件中，我都要写 `var xxx = require('xxx')`, 如果你是用上面的架构，任务多的时候，估计也会抓狂，因为你会发现 `插件和模块依赖被重复的引入进来`，这样就提高了成本

我不想在子任务文件中重复的引入 `插件或模块依赖`，有没有上面好方法，`stackoverflow` 是个好老师，老师告知：

- 使用 `gulp-load-plugins` 插件
  地址：<https://www.npmjs.com/package/gulp-load-plugins>
- 把子任务封装成模块

#### 代码结构

```javascript
    gulpfile.js
    tasks/
    ├── xxxx.js
    ├── xxxx.js
    └── image.js
```

#### gulpfile.js

```javascript
var gulp = require("gulp"),
  gulpLoadPlugins = require("gulp-load-plugins");
// 这里请查看文档
gulpLoadPlugins.imagemin = require("gulp-imagemin");

require("./tasks/image")(gulp, gulpLoadPlugins);
```

#### image.js

```javascript
module.exports = function (gulp, Plugin) {
  gulp.task("img", function () {
    return gulp
      .src("./images/**/*.*")
      .pipe(
        Plugin.imagemin({
          optimizationLevel: 2,
          progressive: true,
        })
      )
      .pipe(gulp.dest("./imagemini"));
  });
};
```

运行任务 一切正常，此时一个文件测试已经 ok

但是 `./tasks` 下面是有很多的子任务，所以需要一个迭代加载，修改 `gulpfile.js` 如下

```javascript
var gulp = require("gulp"),
  gulpLoadPlugins = require("gulp-load-plugins"),
  // 这里获取子任务文件列表 使用了 fs 模块
  gulpTaskList = require("fs").readdirSync("./tasks/");
// 这里请查看文档
gulpLoadPlugins.imagemin = require("gulp-imagemin");

gulpTaskList.forEach(function (taskfile) {
  require("./tasks/" + taskfile)(gulp, gulpLoadPlugins);
});
```

这一次迭代避免了`重复依赖`的问题，但是你会发现，所有的依赖都声明在 `gulpTaskList` 命名空间下，如果你依赖很多插件或模块，`gulpfile.js` 也是相当长，鱼和熊掌不可兼得，在现在情况下，只能寻找最佳的解决方案

### 4 重构迭代 3: 参数配置全局化

其实第二部迭代之后，就可以满足大部分需求，但还是有小伙伴抱怨，有些子任务有相同的参数，能不能抽取出来，放到一个单独的文件中，so 继续翻阅文档

参考文档<https://github.com/gulpjs/gulp/blob/master/docs/recipes/using-external-config-file.md>

#### 代码结构

```javascript
    gulpfile.js
    gulp
    ├── config.json
    ├── tasks/
        ├── xxxx.js
        ├── xxxx.js
        └── image.js
```

`注意：文件夹层次变了`

#### config.json

```javascript
    {
        "pnglevel": 2
    }
```

#### gulpfile.js

```javascript
    var gulp = require('gulp')
      , config = require('./gulp/config.json');
      , gulpLoadPlugins = require('gulp-load-plugins')
      , gulpTaskList = require('fs').readdirSync('./gulp/tasks/')
      ;

    gulpLoadPlugins.imagemin = require('gulp-imagemin');

    gulpTaskList.forEach(function(taskfile) {
        require('./gulp/tasks/' + taskfile)(gulp, gulpLoadPlugins, config);
    });
```

#### image.js

```javascript
module.exports = function (gulp, Plugin, config) {
  gulp.task("img", function () {
    return gulp
      .src("./images/**/*.*")
      .pipe(
        Plugin.imagemin({
          optimizationLevel: config.pnglevel,
          progressive: true,
        })
      )
      .pipe(gulp.dest("./imagemini"));
  });
};
```

此次迭代结束后，我把子任务中通用的配置都写到 `./gulp/config.json` 中，全局配置

### 5 重构迭代 4: 参数配置模块化

此次迭代紧跟迭代 3，`json` 不够完美，不想每次去写 `""`, 这里我把配置文件封装成一个模块

即迭代 3 中的 `config.json` 变成了 `config.js`

#### config.js

```javascript
module.exports = function () {
  var config = {
    pnglevel: 2,
  };
  return config;
};
```

#### gulpfile.js 加载

```javascript
var config = require("./gulp/gulp.config")();
```

其他不变，当封装成一个模块的时候，你就发现好处多多了，可以在模块中添加函数，你也可以把配置拆分，根据你的业务需要，自由调整

### 6 后记

通过 4 步的迭代，整个代码组织架构就清晰多了，很感谢这么多热爱开源，乐于助人的朋友，谢谢

注意：子任务中注意文件夹的层次，子任务中的文件夹是以 `gulpfile.js` 为基准，因为 `gulpfile.js` 把子任务都包含进来了
