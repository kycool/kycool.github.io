---
title: Antd：Form 的 InitialValues 重置
tags:
  - redux
  - Antd
categories:
  - - 前端
abbrlink: 59046
date: 2020-03-03 22:07:53
---

描述：编辑页面中 `Form` 的 `InitialValues` 的重置

<!--more-->

### 1 场景描述

管理后台的通用场景，列表页面，然后点击新建或者更新，这里说的是更新的场景，异步请求，重新渲染表单。

管理后台使用 `antd-pro` 搭建，`antd` 使用了 `4.x` 版本，注意这个版本对 `Form` 做了些调整。

点击更新进入表单页面，我设置了 `state` 的初始值

```javascript
state = {
  initialValues: {},
};
```

然后异步请求，请求到结果后，需要重置 `initialValues`，但是根据 `antd` 的文档

```javascript
initialValue 表单默认值，只有初始化以及重置时生效
```

所以异步请求后如果重新 `setState({ initialValues })`，这样是无效的，你会看到对应的表单中没有数据，都是空的。只能重置，这种问题怎么解决掉

### 2 重置 initialValues

**2.1 如果是函数式组件，官方推荐使用 `Form.useForm` 创建表单数据域进行控制**

使用用法如下：

```javascript
const [form] = Form.useForm();

// 在异步请求中重置表单初始值
asyncRequest().then((initialValues) => form.setFieldsValue({ initialValues }));
```

**2.2 如果是在 class component 下，你也可以通过 ref 获取数据域**

```javascript
class Demo extends React.Component {
  formRef = React.createRef();

  UNSAFE_componentWillMount = () => {
    // 在异步请求中重置表单初始值
    asyncRequest().then((initialValues) => {
      this.formRef.current.setFieldsValue({ initialValues });
    });
  };
}
```

对于 `UNSAFE_componentWillMount` 声明周期函数，有些声明周期函数在未来版本中会被移除或者重命名，这个可以浏览 https://reactjs.org/blog/2018/03/27/update-on-async-rendering.html

### 3 完整的参考示例

这里我使用了类组件

```javascript
import React from "react";
import { Form, Input, Button } from "antd";
import FairyUploader from "@/fairy/components/Uploader";
import FairyRichTextEditor from "@/fairy/components/RichTextEditor";
import store from "@/utils/store";

export default class CreateUpdateForm extends React.Component {
  state = {
    create: true,
    initialValues: {},
  };

  formRef = React.createRef();

  async UNSAFE_componentWillMount() {
    const { id } = this.props.match.params;

    // 获取数据详情
    if (id) {
      this.setState({ create: false });
      store
        .dispatch({
          type: "product/retrieve",
          payload: { id },
        })
        .then((initialValues) => {
          this.formRef.current.setFieldsValue(initialValues);
        });
    }
  }

  onFinish = (values) => {
    console.log("Success:", values);
  };

  onFinishFailed = (errorInfo) => {
    console.log("Failed:", errorInfo);
  };

  render() {
    const { initialValues, create } = this.state;
    const formProps = {
      name: "basic",
      onFinish: this.onFinish,
      onFinishFailed: this.onFinishFailed,
      initialValues,
      ref: this.formRef,
    };

    return (
      <Form {...formProps}>
        <Form.Item
          label="姓名"
          name="name"
          rules={[{ required: true, message: "请填写姓名" }]}
        >
          <Input />
        </Form.Item>

        <Form.Item
          label="职业"
          name="position"
          rules={[{ required: true, message: "请输入职业" }]}
        >
          <Input />
        </Form.Item>

        <Form.Item
          label="头像"
          name="avatar"
          rules={[{ required: true, message: "请上传头像" }]}
        >
          <FairyUploader />
        </Form.Item>

        <Form.Item
          label="描述"
          name="description"
          rules={[{ required: true, message: "请输入描述" }]}
        >
          <FairyRichTextEditor />
        </Form.Item>

        <Form.Item>
          <Button type="primary" htmlType="submit">
            {create ? "保存" : "更新"}
          </Button>
        </Form.Item>
      </Form>
    );
  }
}
```

### 4 小结

- `antd` 对于各种使用场景还是给出了详细的说明和例子参考的，这个很赞。
- 使用 `React` 的各种警告，这个需要认真根据官方的引导进行调整。
- 根据上面的参考示例可以想到对于这种通用的更新创建表单，完全可以使用通用的 `HOC`，根据不同的配置渲染出不同的页面，这样一个高阶组件可以解决掉通用的创建更新表单。同样，对于列表页面也是如此，其实说白了，管理后台可以根据配置生成出来。对于一些需要自定义的业务，可以让高阶组件支持继承和钩子的重置来解决，如果实在解决不了的业务，可以单独写页面也是可以的。对于这个，我会专门写一篇文章来陈述下。
