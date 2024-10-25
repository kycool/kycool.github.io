---
title: 简单备份文件并发送到指定邮箱
tags:
  - Shell
categories:
  - - 后端
  - - Python
abbrlink: 13676
date: 2017-08-10 23:09:32
---

### 1 背景

一哥们发了个诉求，总觉得自己的服务器不安全，想搞个定时备份文件并发送到自己的邮箱

<!--more-->

### 2 实现代码如下

```python
# -*- coding: utf-8 -*-

from __future__ import absolute_import, unicode_literals

import os
import datetime
import logging
import logging.config

from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText
from email.header import Header
from email.mime.application import MIMEApplication
import smtplib

name = datetime.datetime.now().strftime("%Y%m%d%H%M%S")
base_path = '/root/xxxx/temp'
zip_path = '/root/xxxx/backup/{}.tar.bz2'.format(name)


def set_logging():
    """"""

    log_dir, log_file = '/root/xxxx/logs', '/root/xxxx/logs/backup.log'

    if not os.path.exists(log_dir):
        os.mkdir(log_dir)

    if not os.path.exists(log_file):
        open(log_file, 'w')

    DEFAULT_LOGGING = {
        'version': 1,
        'disable_existing_loggers': False,
        'formatters': {
            'formatone': {
                'format': '[%(asctime)s] %(levelname)s : %(message)s',
            }
        },
        'handlers': {
            'file': {
                'level': 'DEBUG',
                'filename': '/root/xxxx/logs/backup.log',
                'formatter': 'formatone',
                'class': 'logging.handlers.RotatingFileHandler',
                'maxBytes': 100 * 1024 * 1024,
                'backupCount': 10,
            },
        },
        'loggers': {
            'backup': {
                'handlers': ['file'],
                'level': 'INFO',
            },
        }
    }

    logging.config.dictConfig(DEFAULT_LOGGING)


def zip_files():
    """zip files"""
    os.system('tar -cjf {} -C {} data'.format(zip_path, base_path))


def sendmail():
    """send mail"""
    set_logging()
    zip_files()

    logger = logging.getLogger('backup')

    mail_from, password = 'xxxxxxx@aliyun.com', 'xxxxxxx'
    mail_to = 'xxxxx@qq.com'
    smtp_server = 'smtp.aliyun.com'

    msgRoot = MIMEMultipart('related')
    msgRoot['Subject'] = 'send backup files {}'.format(name)
    msgRoot['From'] = '{}<{}>'.format(Header('backup', 'utf-8'), mail_from)
    msgRoot['To'] = mail_to

    msgText = MIMEText('backup files', 'plain', 'utf-8')
    msgRoot.attach(msgText)

    zip_con = MIMEApplication(open(zip_path,'rb').read())
    zip_con.add_header('Content-Disposition', 'attachment',
                       filename='{}.tar.bz2'.format(name))
    msgRoot.attach(zip_con)

    try:
        server = smtplib.SMTP_SSL(smtp_server)
        server.login(mail_from, password)
        server.sendmail(mail_from, mail_to, msgRoot.as_string())
        server.quit()
        logger.info('send {} backup files success'.format(name))
    except Exception, e:
        logger.error('send {} failed {}'.format(name, e))
        sendmail()


if __name__ == '__main__':
    sendmail()
```

### 3 简单说明

#### 3.1 打包文件

这个实现比较初级，直接用 `shell` 命令进行打包

```python
def zip_files():
    """zip files"""
    os.system('tar -cjf {} -C {} data'.format(zip_path, base_path))
```

#### 3.2 发送邮件

这个就不说了，现成的模块直接拿来用

#### 3.3 日志记录

加上日志，可以很清楚的让我知道发送情况如下，示例如下：

```javascript
[2017-04-14 00:00:03,251] INFO : send 20170414000001 backup files success
[2017-04-14 03:00:02,620] INFO : send 20170414030001 backup files success
[2017-04-14 06:00:02,406] INFO : send 20170414060001 backup files success
[2017-04-14 09:00:02,349] INFO : send 20170414090001 backup files success
[2017-04-14 12:00:02,299] INFO : send 20170414120001 backup files success
[2017-04-14 15:01:04,696] ERROR : send 20170414150001 failed [Errno 110] Connection timed out
[2017-04-14 15:01:05,401] INFO : send 20170414150001 backup files success
```

#### 3.4 定时处理

定时这个处理，直接使用 `crontab` 命令，创建个 `backup_cron` 文件，写入

```shell
0 */3 * * *  python /root/xxxxx/backup.py
```

### 4 简单小结

业务比较简单，实现也比较简单，没啥可说的
