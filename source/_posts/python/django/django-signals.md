---
title: Django | 信号使用思考
abbrlink: 51727
date: 2023-04-18 14:26:26
tags:
  - Django
categories:
  - - 后端
  - - Python
---

重拾些许关于信号模块使用的记忆，记录对于 `Django` 信号使用的思考。 <!-- more -->

> 本文使用的 Django 的版本是 4.2

# 1 源码注释

```python
import logging
import threading
import weakref

from django.utils.inspect import func_accepts_kwargs

logger = logging.getLogger("django.dispatch")


def _make_id(target):
    """
    对传递进来的函数生成对应的标识，这里使用了 id 函数
    """

    # 如果对象具有 __func__ 属性，则意味着函数是类中的函数
    if hasattr(target, "__func__"):
        return (id(target.__self__), id(target.__func__))
    return id(target)

# None 对应的标识，意味着无意义的键
NONE_ID = _make_id(None)

# A marker for caching
NO_RECEIVERS = object()


class Signal:
    """
    Base class for all signals

    Internal attributes:

        receivers
            { receiverkey (id) : weakref(receiver) }
    """

    def __init__(self, use_caching=False):
        """
        创建一个新的信号对象

        Create a new signal.
        """
        # 接收器列表，好比订阅者列表
        self.receivers = []

        # Django 的 Signal 系统需要处理多线程环境中的并发问题。在多线程应用中，可能会有
        # 多个线程同时操作 Signal 对象，例如连接或断开接收器、发送信号等。为了确保 Signal
        # 对象在多线程环境中的一致性和线程安全，Django 使用 threading.Lock 对关键
        # 部分的代码进行加锁。
        self.lock = threading.Lock()

        # 是否使用缓存
        self.use_caching = use_caching

        # For convenience we create empty caches even if they are not used.
        # A note about caching: if use_caching is defined, then for each
        # distinct sender we cache the receivers that sender has in
        # 'sender_receivers_cache'. The cache is cleaned when .connect() or
        # .disconnect() is called and populated on send().
        # 缓存发送者对象和对应的接收器
        self.sender_receivers_cache = weakref.WeakKeyDictionary() if use_caching else {}

        # 标识是否存在已经失效的接收器
        self._dead_receivers = False

    def connect(self, receiver, sender=None, weak=True, dispatch_uid=None):
        """
        用于将信号接收器（receiver）注册到信号对象（signal）。接收器是一个函数，当信号
        被发送时，对应发送者所有对应的接收器将被触发

        Connect receiver to sender for signal.

        Arguments:

            receiver 接收器

                接收器是一个用来接收信号的函数或者对象的方法，接收器必须可 hash。
                A function or an instance method which is to receive signals.
                Receivers must be hashable objects.

                当 weak 为 True 时，接收器一定可以被弱引用。
                If weak is True, then receiver must be weak referenceable.

                接收器必须可以接受关键字参数
                Receivers must be able to accept keyword arguments.

                如果一个接收器（A) 连接时，使用了 dispatch_uid 参数，那么如果其他接收器（B）连接时，
                使用了同样的 dispatch_uid，那么接收器（A）将不会被添加，即 dispatch_uid 不能重复。
                If a receiver is connected with a dispatch_uid argument, it
                will not be added if another receiver was already connected
                with that dispatch_uid.

            sender 发送者
                一个用于触发接收器响应的对象。如果为 sender 设置一个具体的对象，那么只有来自该
                对象发送的信号才会触发接收器。如果省略 sender 参数，那么该接收器将响应所有发送者的信号。
                在 django 的调用中，多处基本上都是类。例如 request_started 信号对应的发送者是
                class 'django.core.handlers.wsgi.WSGIHandler'

                The sender to which the receiver should respond. Must either be
                a Python object, or None to receive events from any sender.

            weak 弱引用
                是否使用对接收器的弱引用。默认情况下，该模块将尝试使用弱引用来引用接收器。
                如果这个参数为 false，那么将使用强引用

                Whether to use weak references to the receiver. By default, the
                module will attempt to use weak references to the receiver
                objects. If this parameter is false, then strong references will
                be used.

            dispatch_uid
                在可能发送重复信号的情况下，信号接收器的唯一标识符

                一个用于唯一地标识一个特定接收器对象的标识符，它通常是一个字符串，虽然它可以是
                任何可哈希的东西。

                An identifier used to uniquely identify a particular instance of
                a receiver. This will usually be a string, though it may be
                anything hashable.
        """
        from django.conf import settings

        # If DEBUG is on, check that we got a good receiver
        # 如果开启 DEBUG 模式，检测接收器是否符合要求
        if settings.configured and settings.DEBUG:
            if not callable(receiver):
                raise TypeError("Signal receivers must be callable.")
            # Check for **kwargs
            # 检查接收器接收的是否都是关键字参数
            if not func_accepts_kwargs(receiver):
                raise ValueError(
                    "Signal receivers must accept keyword arguments (**kwargs)."
                )

        # 如果指定了 dispatch_uid，则优先使用 dispatch_uid，所以针对同一个信号，同样的发送者
        # dispatch_uid 是不能重复的，否则后续验证 lookup_key 已经存在的话，接收器则不会加入
        # 到接收器列表。
        if dispatch_uid:
            lookup_key = (dispatch_uid, _make_id(sender))
        else:
            lookup_key = (_make_id(receiver), _make_id(sender))

        # 默认使用弱引用，这个也是弱引用的妙用之处。
        if weak:
            ref = weakref.ref
            receiver_object = receiver
            # Check for bound methods
            if hasattr(receiver, "__self__") and hasattr(receiver, "__func__"):
                ref = weakref.WeakMethod
                receiver_object = receiver.__self__
            receiver = ref(receiver)
            weakref.finalize(receiver_object, self._remove_receiver)

        with self.lock:
            # 清除无效的接收器
            self._clear_dead_receivers()
            if not any(r_key == lookup_key for r_key, _ in self.receivers):
                # 如果接收器对应的键不在信号对象的接收器列表中，则加入到接收器列表中
                self.receivers.append((lookup_key, receiver))
            # 清除 sender_receivers_cache 缓存
            self.sender_receivers_cache.clear()

    def disconnect(self, receiver=None, sender=None, dispatch_uid=None):
        """
        为指定的发送者对象移除对应的接收器

        Disconnect receiver from sender for signal.

        如果使用了弱引用，disconnect 函数不需要调用。因为弱引用的接收器会自动移除。

        If weak references are used, disconnect need not be called. The receiver
        will be removed from dispatch automatically.

        Arguments:

            receiver
                The registered receiver to disconnect. May be none if
                dispatch_uid is specified.

            sender
                The registered sender to disconnect

            dispatch_uid
                the unique identifier of the receiver to disconnect
        """
        # 计算索引键
        if dispatch_uid:
            lookup_key = (dispatch_uid, _make_id(sender))
        else:
            lookup_key = (_make_id(receiver), _make_id(sender))

        disconnected = False
        with self.lock:
            self._clear_dead_receivers()
            # 通过对比索引键，如果存在，则进行删除
            for index in range(len(self.receivers)):
                (r_key, _) = self.receivers[index]
                if r_key == lookup_key:
                    disconnected = True
                    del self.receivers[index]
                    break
            # 删除完后需要重置 sender_receivers_cache 缓存
            self.sender_receivers_cache.clear()

        # 返回是否断开的标识，数据类型为布尔型
        return disconnected

    def has_listeners(self, sender=None):
        """是否存在指定发送者有效的接收器"""
        return bool(self._live_receivers(sender))

    def send(self, sender, **named):
        """
        发送信号到指定发送者的接收器中

        Send signal from sender to all connected receivers.

        If any receiver raises an error, the error propagates back through send,
        terminating the dispatch loop. So it's possible that all receivers
        won't be called if an error is raised.

        Arguments:

            sender
                The sender of the signal. Either a specific object or None.

            named
                Named arguments which will be passed to receivers.

        Return a list of tuple pairs [(receiver, response), ... ].
        """
        if not self.receivers or self.sender_receivers_cache.get(sender) is NO_RECEIVERS:
            return []

        return [(receiver, receiver(signal=self, sender=sender, **named)) for receiver in self._live_receivers(sender)]

    def send_robust(self, sender, **named):
        """
        Send signal from sender to all connected receivers catching errors.

        Arguments:

            sender
                The sender of the signal. Can be any Python object (normally one
                registered with a connect if you actually want something to
                occur).

            named
                Named arguments which will be passed to receivers.

        Return a list of tuple pairs [(receiver, response), ... ].

        If any receiver raises an error (specifically any subclass of
        Exception), return the error instance as the result for that receiver.
        """
        if not self.receivers or self.sender_receivers_cache.get(sender) is NO_RECEIVERS:
            return []

        # Call each receiver with whatever arguments it can accept.
        # Return a list of tuple pairs [(receiver, response), ... ].
        responses = []
        for receiver in self._live_receivers(sender):
            try:
                response = receiver(signal=self, sender=sender, **named)
            except Exception as err:
                logger.error(
                    "Error calling %s in Signal.send_robust() (%s)",
                    receiver.__qualname__,
                    err,
                    exc_info=err,
                )
                responses.append((receiver, err))
            else:
                responses.append((receiver, response))
        return responses

    def _clear_dead_receivers(self):
        """清除无效的接收器"""
        # Note: caller is assumed to hold self.lock.
        if self._dead_receivers:
            self._dead_receivers = False

            # 迭代处理，获取有效的接收器
            # - 如果是强引用，这直接略过
            # - 如果是弱引用，弱引用对象执行为 None，则代表是无效的接收器
            self.receivers = [
                r for r in self.receivers if not (isinstance(r[1], weakref.ReferenceType) and r[1]() is None)
            ]

    def _live_receivers(self, sender):
        """
        根据指定的发送者获取接收器列表

        Filter sequence of receivers to get resolved, live receivers.

        This checks for weak references and resolves them, then returning only
        live receivers.
        """
        # 初始化接收器列表对象
        receivers = None

        # 如果使用了缓存，同时 _dead_receivers 为 False 时
        if self.use_caching and not self._dead_receivers:
            # 直接通过发送者对象获取接收器列表
            receivers = self.sender_receivers_cache.get(sender)
            # We could end up here with NO_RECEIVERS even if we do check this case in
            # .send() prior to calling _live_receivers() due to concurrent .send() call.
            # 如果接收器列表为空，则不做任何动作，直接返回
            if receivers is NO_RECEIVERS:
                return []

        # 如果接收器列表为 None
        if receivers is None:
            with self.lock:
                # 清除无效的接收器
                self._clear_dead_receivers()
                senderkey = _make_id(sender)
                receivers = []

                # 根据发送者校验，获取发送者对象对应的接收器列表
                for (receiverkey, r_senderkey), receiver in self.receivers:
                    # 因为 sender 在有些信号对象中是为 None，所以需要判断是否是 NONE_ID
                    if r_senderkey == NONE_ID or r_senderkey == senderkey:
                        receivers.append(receiver)

                # 如果使用管理缓存，则进行缓存
                if self.use_caching:
                    if not receivers:
                        self.sender_receivers_cache[sender] = NO_RECEIVERS
                    else:
                        # Note, we must cache the weakref versions.
                        self.sender_receivers_cache[sender] = receivers
        non_weak_receivers = []

        # 迭代处理获取非弱引用的接收器（即正常的接收器）
        for receiver in receivers:
            if isinstance(receiver, weakref.ReferenceType):
                # Dereference the weak reference.
                receiver = receiver()
                if receiver is not None:
                    non_weak_receivers.append(receiver)
            else:
                # 如果是强引用，则直接加入
                non_weak_receivers.append(receiver)
        return non_weak_receivers

    def _remove_receiver(self, receiver=None):
        """
        当弱引用引用的对象不存在时，给当前的信号标识存在无效的接收器

        标注 self.receivers 存在无效的弱引用。如果存在无效的弱引用，
        将在 connect、disconnect 和 _live_receivers 中清理这些
        无效的弱引用对象。
        """

        # Mark that the self.receivers list has dead weakrefs. If so, we will
        # clean those up in connect, disconnect and _live_receivers while
        # holding self.lock. Note that doing the cleanup here isn't a good
        # idea, _remove_receiver() will be called as side effect of garbage
        # collection, and so the call can happen while we are already holding
        # self.lock.
        self._dead_receivers = True


def receiver(signal, **kwargs):
    """
    连接接收器到信号的装饰器，其内部实际上是对 connect 方法的包装，使用装饰器看起来更直观一些。

    A decorator for connecting receivers to signals. Used by passing in the
    signal (or list of signals) and keyword arguments to connect::

        @receiver(post_save, sender=MyModel)
        def signal_receiver(sender, **kwargs):
            ...

        @receiver([post_save, post_delete], sender=MyModel)
        def signals_receiver(sender, **kwargs):
            ...
    """

    def _decorator(func):
        if isinstance(signal, (list, tuple)):
            for s in signal:
                s.connect(func, **kwargs)
        else:
            signal.connect(func, **kwargs)
        return func

    return _decorator
```

# 2 函数清单

## 2.1 \_make_id 方法

```python
def _make_id(target):
    if hasattr(target, "__func__"):
        return (id(target.__self__), id(target.__func__))
    return id(target)
```

首先认真分析下其业务实现，`target` 参数是接收器（即普通的函数或者是 `bound` 方法）

- 如果是普通的函数，则使用 `id` 函数获取 `target` 的唯一标识，返回的类型是整型，即一个数字。
- 如果是 `bound` 方法，返回的结果是一个元组，其元组包含两个元素，其中第一个元素是 `target` 所关联对象的唯一标识，第二个元素是 `target` 的唯一标识。

同时参考下 `connect` 方法中对 `_make_id` 的调用，下面摘取一些片段

```python
        if dispatch_uid:
            lookup_key = (dispatch_uid, _make_id(sender))
        else:
            lookup_key = (_make_id(receiver), _make_id(sender))

        # 省略代码

        with self.lock:
            # 省略代码
            if not any(r_key == lookup_key for r_key, _ in self.receivers):
                # 如果接收器对应的键不在信号对象的接收器列表中，则加入到接收器列表中
                self.receivers.append((lookup_key, receiver))
            # 省略代码
```

可以清楚的看到 `lookup_key` 是一个元组，因为我们这里重点关注了接收器，所以就元组的第一个元素做些说明，元组的第一个元素，根据接收器的类型，所以有可能是一个数字，也有可能是一个元组。接下来使用一个示例验证下。

```python
from django.core.signals import request_started
from django.dispatch import receiver


class CustomSignal:
    def bound_method(self, signal=None, sender=None, environ=None, **kwargs):
        print("bound method receiver run")
        print(request_started.receivers)


custom_signal = CustomSignal()
request_started.connect(custom_signal.bound_method)


@receiver(request_started)
def common_function(signal=None, sender=None, environ=None, **kwargs):
    print("common method receiver run")
```

这个示例针对 request_started 信号做了两个接收器

- `bound` 方法：custom_signal.bound_method
- 普通函数：common_function

然后执行后看下结果：

```
bound method receiver run
[
    ((4507063040, 4496364336), <weakref at 0x10ca179c0; to 'function' at 0x10ca45300 (reset_queries)>),
    ((4507064640, 4496364336), <weakref at 0x10ca509a0; to 'function' at 0x10ca45940 (close_old_connections)>),
    (((4522035984, 4521976480), 4496364336), <weakref at 0x10d859310; to 'CustomSignal' at 0x10d88cb10>),
    ((4521976640, 4496364336), <weakref at 0x10d888b80; to 'function' at 0x10d87e340 (common_function)>)
]
common method receiver run
```

根据执行结果可以清楚的看到

- 如果是 bound 方法：`lookup_key` 是 `((4522035984, 4521976480), 4496364336)`，元组的第一个元素也是一个元组，原型即 `(id(target.__self__), id(target.__func__))`
- 如果是普通的函数：`lookup_key` 是 `(4521976640, 4496364336)`

## 2.2 为什么要使用 threading.Lock

`Django` 的 `Signal` 系统需要处理多线程环境中的并发问题。在多线程应用中，可能会有多个线程同时操作 `Signal` 对象，例如连接或断开接收器、发送信号等。为了确保 `Signal` 对象在多线程环境中的一致性和线程安全，`Django` 使用 `threading.Lock` 对关键部分的代码进行加锁。

`threading.Lock` 是 Python 标准库中提供的一个基本同步原语，用于在线程之间提供互斥访问共享资源的能力。通过使用锁，`Django` 可以确保同一时间只有一个线程对 `Signal` 对象进行修改，避免了潜在的竞争条件和不一致问题。

以下是在 `Django Signal` 中使用锁的几个例子：

- 在连接接收器时，`Django` 使用锁来确保线程安全地更新接收器列表。这可以防止在多线程环境中同时连接接收器时导致的不一致状态。

```python
with self.lock:
    self.receivers.append((lookup_key, receiver))

```

- 在断开接收器时，Django 同样使用锁来确保线程安全地从接收器列表中移除接收器

```python
with self.lock:
    for index in range(len(self.receivers)):
        # ...
```

- 在发送信号时，Django 使用锁来确保线程安全地遍历接收器列表并调用相应的接收器。这样可以防止在发送信号的过程中修改接收器列表导致的潜在问题

```python
with self.lock:
    for _, receiver in self.receivers:
        # ...
```

总之，`Django` 使用 `threading.Lock` 来确保 `Signal` 对象在多线程环境中的线程安全。通过在关键代码段中使用锁，可以避免并发修改导致的不一致问题和竞争条件。这使得 Django 的 Signal 系统在多线程应用中能够可靠地工作

## 2.3 sender 和 sender_robust 的区别

这里通过源码可以清楚看到它们之间的区别。

在 `Django` 信号系统中，`sender` 和 `sender_robust` 并没有直接的区别，因为这两个词没有特定的定义。它们都是 `Signal` 类的方法，用于发送信号，但在处理接收器异常时，行为是不同的。下面详细解释这两个方法的区别：

- **send**: `send` 方法用于发送信号。当使用 `send` 发送信号时，它会调用与信号关联的所有接收器。如果接收器引发异常，`send` 会将该异常抛出，导致程序中止。换句话说，`send` 在遇到接收器异常时没有错误处理机制，因此可能导致程序崩溃。

```python
def send(self, sender, **named):
    # ...省略部分代码
    responses = []
    for receiver in self._live_receivers(sender):
        response = receiver(signal=self, sender=sender, **named)
        responses.append((receiver, response))
    return responses
```

- **send_robust**: `send_robust` 方法与 `send` 类似，也用于发送信号。但是，它会处理接收器抛出的异常。如果接收器引发异常，`send_robust` 会捕获异常并将其添加到响应列表，而不是中断程序。这意味着，在使用 `send_robust` 时，程序会继续运行，即使某个接收器抛出了异常。

```python
def send_robust(self, sender, **named):
    # ...省略部分代码
    responses = []
    for receiver in self._live_receivers(sender):
        try:
            response = receiver(signal=self, sender=sender, **named)
            responses.append((receiver, response))
        except Exception as err:
            responses.append((receiver, err))
    return responses
```

总之，`send` 和 `send_robust` 的主要区别在于它们如何处理接收器抛出的异常。`send` 方法在遇到异常时会中断程序，而 `send_robust` 会捕获异常并将其添加到响应列表，以便在后续处理。`send_robust` 为程序提供了更健壮的错误处理，因此在处理潜在的接收器错误时更安全。

## 2.4 \_live_receivers 辅助函数

**\_live_receivers** 是一个内部辅助函数，用于筛选出有效的接收器列表。在发送信号时，`Django` 需要找到所有活跃的、有效的接收器来响应信号。由于某些接收器可能使用弱引用（`weak reference`）来避免循环引用问题，当接收器指向的对象被销毁时，弱引用将不再有效。因此，在发送信号前，需要筛选出仍然有效的接收器。
