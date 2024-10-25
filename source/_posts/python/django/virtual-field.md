---
title: Django | 虚拟字段
tags:
  - Django
categories:
  - - 后端
  - - Python
abbrlink: 37001
date: 2020-04-26 17:07:09
---

这次写写 Django 模型中的虚拟字段。这个虚拟字段很有意思，在某些场景下，反查可以让业务代码看起来很清晰，大部分时候都是结合 `prefetch_related` 和 `select_related` 来使用。<!--more-->

### 1 模型

```python
class Category(models.Model):
    user = models.ForeignKey(
        to=settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='category_user',
        null=True,
        default=None,
    )

class Article(models.Model):
    user = models.OneToOneField(to=settings.AUTH_USER_MODEL, on_delete=models.CASCADE)
    category = models.ManyToManyField(Category)

class Book(models.Model):
    article = models.OneToOneField(
        Article, on_delete=models.CASCADE, related_name='books'
    )

class Tag(models.Model):
    article = models.ForeignKey(Article, on_delete=models.CASCADE)
    users = models.ManyToManyField(User, related_name='tag_users')
```

这里写了分类模型和文章模型，里面包含了基本的三种关系：

- OneToOneField
- ForeignKey
- ManyToManyField

### 2 模型中的虚拟字段

虚拟字段一般存在于父模型中。对于上述三种关系，虚拟字段的名称都会受是否指定 `related_name` 的影响。

**规则 1：**

> 如果引用模型指定了 related_name，那么父模型（被引用模型）存在指定的 related_name 名称的字段

**规则 2：**

> 如果没有指定 related_name，那么父模型（被引用模型）存在子模型小写名称的字段

#### 2.1 OneToOneField 关系下的验证

##### 2.1.1 指定了 related_name

```python
In [5]: Article._meta.get_field('books')
Out[5]: <OneToOneRel: mallshop.book>

In [7]: Article._meta.get_field('books').concrete
Out[7]: False
```

`Book` 模型引用了 `Article` 模型，同时指定了 `related_name`, 这时 `Article` 模型存在 `books` 的虚拟字段

##### 2.1.2 没有指定 related_name

```python
In [8]: User._meta.get_field('article')
Out[8]: <OneToOneRel: mallshop.article>

In [9]: User._meta.get_field('article').concrete
Out[9]: False
```

`Article` 模型引用了 `User` 模型，没有指定 `related_name`，这时 `User` 模型存在 `artilce` 虚拟字段

#### 2.2 ForeignKey 关系下的验证

##### 2.2.1 指定了 related_name

```python
In [10]: User._meta.get_field('category_user')
Out[10]: <ManyToOneRel: mallshop.category>

In [11]: User._meta.get_field('category_user').concrete
Out[11]: False
```

`Category` 模型引用了 `User` 模型，同时指定了 `related_name`, 这时 `User` 模型存在 `category_user` 的虚拟字段

##### 2.2.2 没有指定 related_name

```python
In [12]: Article._meta.get_field('tag')
Out[12]: <ManyToOneRel: mallshop.tag>

In [13]: Article._meta.get_field('tag').concrete
Out[13]: False
```

`Tag` 模型引用了 `Article 模型`，没有指定 `related_name`，这时 `Article` 模型存在 `tag` 虚拟字段

#### 2.3 ManyToManyField 关系下的验证

##### 2.3.1 指定了 related_name

```python
In [1]: User._meta.get_field('tag_users')
Out[1]: <ManyToManyRel: mallshop.tag>

In [2]: User._meta.get_field('tag_users').concrete
Out[2]: False
```

`Tag` 模型引用了 `User` 模型，同时指定了 `related_name` 为 `tag_users`, 这时 `User` 模型存在 `tag_users` 的虚拟字段

##### 2.3.2 没有指定 related_name

```python
In [15]: Category._meta.get_field('article')
Out[15]: <ManyToManyRel: mallshop.article>

In [16]: Category._meta.get_field('article').concrete
Out[16]: False
```

`Article` 模型引用了 `Category` 模型，没有指定 `related_name`，这时 `Category` 模型存在 `article` 虚拟字段

### 3 模型实例访问虚拟字段

如果在模型实例，访问虚拟字段时，这里需要注意以下规则：

**规则 1：**

> 如果是 OneToOneField 关系，访问模型实例的虚拟字段属性时，这时返回的是子模型的实例

```python
In [3]: user = User.objects.first()

In [4]: user.article
Out[4]: <Article: Article object (1)>

In [5]: user.article.books
Out[5]: <Book: Book object (1)>
```

**规则 2：**

> 如果是非 OneToOneField 关系，同时指定了 related_name，访问模型实例的虚拟字段属性时，这时返回的是 RelatedManager 实例

```python
In [9]: user.category_user
Out[9]: <django.db.models.fields.related_descriptors.create_reverse_many_to_one_manager.<locals>.RelatedManager at 0x107c10610>
```

**规则 3：**

> 如果是非 OneToOneField 关系，同时没有指定 related_name，访问模型实例的虚拟字段属性时，这个时候会抛出异常，如果想得到一个 RelatedManager 实例，则需要在虚拟字段后加上 \_set 后，在进行访问

```python
In [6]: article = Article.objects.first()

In [7]: article.tag
---------------------------------------------------------------------------
AttributeError                            Traceback (most recent call last)
<ipython-input-7-ad987724bf64> in <module>
----> 1 article.tag

AttributeError: 'Article' object has no attribute 'tag'

In [8]: article.tag_set
Out[8]: <django.db.models.fields.related_descriptors.create_reverse_many_to_one_manager.<locals>.RelatedManager at 0x108053220>
```

### 4 小结

虚拟字段，注意在模型和模型实例下的使用方式。

话说虚拟字段有啥用，可以反查，在我使用的场景中，最大的好处是可以基于 `DRF` 动态构建序列化类，例如想得到一篇文章，这个文章还要包含些作者信息，前端可以这样传

```json
{
  "display_fields": [
    "id",
    "name",
    { "user": ["username", "id"] },
    { "tag": ["id", "name"] }
  ]
}
```

返回的结果

```json
{
  "id": 1,
  "name": "ceshi1",
  "user": {
    "username": "吴小楠",
    "id": 2
  },
  "tag": [
    {
      "id": 3,
      "name": "tag1"
    }
  ]
}
```

后端可以根据前端传递的获取字段列表进行校验，验证通过后根据获取的字段动态的生成对应的序列化类，嵌套的序列化类也只包含指定的字段，这样在服务端可以提升些接口性能。返回给前端，这个我是参考了 `graphql` 的模式，前端需要返回什么，就指定什么。

如果使用 Django，虚拟字段的使用时避免不了的，深度挖掘虚拟字段的使用，会跟业务带来很大的便利性。
