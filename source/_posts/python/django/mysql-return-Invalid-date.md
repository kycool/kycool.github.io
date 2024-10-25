---
title: Django | Mysql 返回不合法的日期时间对象
tags:
  - Django
  - Mysql
categories:
  - - 后端
  - - Python
description: 返回不合法的日期时间对象
abbrlink: 26483
date: 2018-05-10 00:53:13
---

### 1 错误描述

在查询数据集中的日期时间对象时

```python
In [38]: Device.objects.datetimes('latest_alarm_time', 'month')

Out[38]: SELECT DISTINCT
CAST(DATE_FORMAT(CONVERT_TZ(`device_device`.`latest_alarm_time`, 'UTC', 'Asia/Shanghai'), '%Y-%m-01 00:00:00') AS DATETIME) AS `datetimefield` FROM `device_device` WHERE `device_device`.`latest_alarm_time` IS NOT NULL ORDER BY `datetimefield` ASC LIMIT 21
```

然后报错

```python
ValueError: Database returned an invalid datetime value. Are time zone definitions for your database installed?
```

### 2 解决问题

实际情况，数据库中是有数据，目测月份提取失败；到 mysql 执行了下

```python
mysql root@localhost:py365> select convert_tz('2018-05-10 12:30:00', 'UTC', 'Asia/Shanghai');
+-------------------------------------------------------------+
| convert_tz('2018-05-10 12:30:00', 'UTC', 'Asia/Shanghai')   |
|-------------------------------------------------------------|
| NULL                                                        |
+-------------------------------------------------------------+
```

果然，结果返回令人诧异的 `NULL`

看了下 Django orm 的 datetimes 官方文档

```python
Note
This function performs time zone conversions directly in the database. As a consequence, your database must be able to interpret the value of tzinfo.tzname(None). This translates into the following requirements:

SQLite: no requirements. Conversions are performed in Python with pytz (installed when you install Django).
PostgreSQL: no requirements (see Time Zones).
Oracle: no requirements (see Choosing a Time Zone File).
MySQL: load the time zone tables with mysql_tzinfo_to_sql.
```

即 mysql 需要使用 mysql_tzinfo_to_sql 载入时区表，接着跳到 <https://dev.mysql.com/doc/refman/8.0/en/mysql-tzinfo-to-sql.html>

按照 mysql 官方的文档

`For the first invocation syntax, pass the zoneinfo directory path name to mysql_tzinfo_to_sql and send the output into the mysql program. For example:`

我需要按照以下命令执行

> mysql_tzinfo_to_sql /usr/share/zoneinfo | mysql -u root mysql

然后再次执行上面执行过的转换语句

```python
mysql root@localhost:py365> select convert_tz('2018-05-10 12:30:00', 'UTC', 'Asia/Shanghai');
+-------------------------------------------------------------+
| convert_tz('2018-05-10 12:30:00', 'UTC', 'Asia/Shanghai')   |
|-------------------------------------------------------------|
| 2018-05-10 20:30:00                                         |
+-------------------------------------------------------------+
```

yes，返回了正确的结果；

在 shell 中 执行数据库查询语句

```python
In [45]: Device.objects.datetimes('latest_alarm_time', 'month')
Out[45]: SELECT DISTINCT CAST(DATE_FORMAT(CONVERT_TZ(`device_device`.`latest_alarm_time`, 'UTC', 'Asia/Shanghai'), '%Y-%m-01 00:00:00') AS DATETIME) AS `datetimefield` FROM `device_device` WHERE `device_device`.`latest_alarm_time` IS NOT NULL ORDER BY `datetimefield` ASC LIMIT 21


Execution time: 0.000591s [Database: default]

<QuerySet [datetime.datetime(2018, 5, 1, 0, 0, tzinfo=<DstTzInfo 'Asia/Shanghai' CST+8:00:00 STD>)]>
```

正常，so 问题解决，看来还得认真看文档呀
