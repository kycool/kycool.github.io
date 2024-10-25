---
title: Mysql | 索引查询
tags:
    - Mysql
categories:
    - - 数据库
abbrlink: 8256
date: 2019-03-01 22:48:43
---

> mysql 版本：8.x

## 1 查询语法

### 1.1 语法解读

```sql
SHOW [EXTENDED] {INDEX | INDEXES | KEYS}
    {FROM | IN} tbl_name
    [{FROM | IN} db_name]
    [WHERE expr]
```

**语法解读**
这是 `SHOW INDEX` 命令的完整语法，下面我将逐个解释每个部分：

-   `SHOW`：这是开始执行命令的关键字。
-   `[EXTENDED]`：这是一个可选的关键字，如果使用了，它会显示隐藏的索引。
-   `{INDEX | INDEXES | KEYS}`：你可以选择其中任何一个关键字，它们都可以用来查看索引信息。这三个关键字在功能上是等价的。
-   `{FROM | IN}`：这两个关键字在这里的功能也是等价的，它们用来指定我们将从哪个表查看索引信息。
-   `tbl_name`：这是你想要查看索引信息的表的名称。
-   `[ {FROM | IN} db_name ]`：这是一个可选的部分，用来指定 `tbl_name` 所在的数据库。如果你已经使用 `USE db_name;` 选择了数据库，那么你可以省略这部分。
-   `[WHERE expr]`：这也是一个可选的部分，可以用来过滤结果。你可以提供一个条件表达式来限制返回的行。例如，你可以使用 `WHERE Key_name = 'PRIMARY'` 来只显示主键的信息。

```sql
SHOW INDEX FROM my_table FROM my_database WHERE Key_name = 'PRIMARY';
```

这个命令将显示数据库 ` my_database`` 中表  `my_table`` 的主键信息。

### 1.2 提醒

**An alternative to tbl_name FROM db_name syntax is db_name.tbl_name**. 下面这两条语句是等价的。

```sql
SHOW INDEX FROM mytable FROM mydb;
SHOW INDEX FROM mydb.mytable;
```

## 2 结果字段

```sql
mysql> show extended index from country in mybatis where Column_name = 'id' \G;
*************************** 1. row ***************************
        Table: country
   Non_unique: 0
     Key_name: PRIMARY
 Seq_in_index: 1
  Column_name: id
    Collation: A
  Cardinality: 5
     Sub_part: NULL
       Packed: NULL
         Null:
   Index_type: BTREE
      Comment:
Index_comment:
      Visible: YES
   Expression: NULL
1 row in set (0.00 sec)
```

下面针对查询结果中每个字段给出详细的解释：

-   **Table**
    表名。

-   **Non_unique**
    如果索引不能包含重复项，则为 `0`；如果可以，则为 `1`。也就是我们平时所说的唯一索引

-   **Key_name**
    索引的名称，如果名字相同则表明是同一个索引，而并不是重复，名字相同的是联合索引。如果索引是主键索引，那么索引名称永远都是 `PRIMARY`

-   **Seq_in_index**
    索引中的列序号，对于多列索引，第一列为 `1`，第二列为 `2`，依此类推。

-   **Column_name**
    索引的列名。

-   **Collation**
    列在索引中的排序方式。有 `A（升序）`，`D（降序）`，`NULL（无排序）`。

-   **Cardinality**
    索引中唯一值的数目的估计值。对于非唯一索引，该值是 `NULL`。要更新这个数字，请运行 ` ANALYZE TABLE` 或（对于 `MyISAM` 表）`myisamchk -a`。

    我们知道某个字段的重复值越少越适合建索引，所以我们一般都是根据 `Cardinality` 来判断索引是否具有高选择性，如果这个值非常小，那就需要重新评估这个字段是否适合建立索引。`Cardinality` 越大，使用此索引的机会就越大。

-   **Sub_part**
    前置索引的意思，如果列只是被部分地编入索引，则为被编入索引的字符数。对于完全编入索引的列，此值为 `NULL`。

-   **Packed**
    MySQL 用来使索引更小的数据压缩方式。此值通常为 `NULL`。压缩一般包括压缩传输协议、压缩列解决方案和压缩表解决方案。

-   **Null**
    如果列可能包含 `NULL` 值，则为 `YES`；否则，则为 `NO`。

-   **Index_type**
    使用的索引方法（例如 `BTREE, FULLTEXT, HASH, RTREE`）。

-   **Comment**
    索引列中未说明的有关索引的信息，例如，如果索引已禁用，则表示已禁用。

-   **Index_comment**
    这个字段包含了在创建索引时指定的注释。例如，在执行 `CREATE INDEX` 或 `ALTER TABLE` 语句时，你可以使用 `COMMENT` 选项来添加注释。。

-   **Visible**
    这个字段在 `MySQL 8.0.12` 及之后的版本中被引入。它表明索引是否是可见的。如果索引是可见的（`Visible` 的值为 `YES`），那么优化器可以选择使用这个索引来执行查
    询。如果索引是不可见的（`Visible` 的值为 `NO`），那么优化器将不会使用这个索引来执行查询。

-   **Expression**
    关于索引的一些注解信息。

请注意，如果你要查看的表在一个特定的数据库中，你可能需要先使用 `USE database_name;` 来选择那个数据库。
