---
title: DRF：书写接口的通用流程
tags:
  - Django
  - Django-Rest-Framework
categories:
  - - 后端
  - - Python
abbrlink: 11214
date: 2016-06-06 23:07:53
---

描述：书写接口的基本流程

<!--more-->

在使用 `django-restful-framework` 写后台接口的业务中，在下通用的做法；

> 前端数据数据---->检测(包含限流，认证，权限验证，数据检测)---->持久化

其中对于限流和权限验证，都可以自定义类解决需求，重点还是在于数据检测，本着不能相信前端输入的数据的原则，要做好数据检测，也不是件轻而易举的事情，毕竟疯子的想法你是猜不透的。

这里针对数据检测，在这里说说我的通用做法，还是以例说明：

### 1 场景：认证服务

这里只是简单的验证用户，根据用户输入的姓名，身份证号码，手机号码（需要填写手机号码是为了短信验证，这年头，不加点料，都对不起自己），验证输入的信息是否合法，当然这个验证不是很靠谱，只是为了做个例子而已，不用太当真，不然掉进了你是谁，我又是谁的黑洞，那就完蛋了。

### 2 业务流程步骤

说明：代码以伪代码为主

#### 2.1 准备两个 serializer

为什么要准备两个 `serializer`，因为：

- 输入的数据结构和你期望返回的数据结构有可能是不一样的
- 业务拆分，保持业务独立，清晰

检测数据的 serializer:

```Python
class VerifyForm(serializers.Serializer):
    """验证认证用户输入数据"""
    username = serializers.CharField(max_length=64, min_length=2)
    id_number = serializers.CharField(max_length=18, min_length=15)
    sms_code = serializers.CharField(max_length=6, min_length=6)

    def validate_username(self, value):
        if 检测输入的用户名不合法:
            raise 异常
        return value

    def validate_id_number(self, value):
        if 检测输入的身份证号码不合法:
            raise 异常
        return value

    def validate_sms_code(self, value):
        if 检测输入的短信验证码不合法:
            raise 异常
        return value

    def validate(self, attrs):
        if 外部服务(username, id_number) 不合法:
            raise 异常
        return attrs

    def create(self, validated_data):
         持久化
         return instance
```

序列化对象的 serializer:

```python
class VerifySerializer(serializers.ModelSerializer):
    """序列化数据"""

    你可以做点自己喜欢的事情，啊哈

    class Meta:
        model = Verify
        fields = '__all__'
```

#### 2.2 书写 views

针对创建的业务，示例如下：

```python
def perform_create(self, serializer):
    return serializer.save()

def create(self, request, *args, **kwargs):
    serializer = VerifyForm(data=request.data, context={'request': request})
    # 检验数据
    serializer.is_valid(raise_exception=True)
    # 持久化
    instance = self.perform_create(serializer)
    # 序列化数据
    serializer = self.get_serializer(instance)

    return Response(serializer.data)
```

### 3 小结

这种做法是我通常写接口业务的流程，验证检测归验证检测，序列化归序列化，两种类型互不干扰，当然对于简单的业务你可以全部放到同一个 serializer 中，这个根据自己的业务需求走，没有更好，只有合适。
