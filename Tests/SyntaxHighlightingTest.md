# PaperMD 语法高亮测试文档

## ATX 风格标题 (H1-H6)

### 三级标题

#### 四级标题

##### 五级标题

###### 六级标题

---

## Setext 风格标题

这是一级标题 (用 === 下划线)
===

这是二级标题 (用 --- 下划线)
---

---

## 文本格式化

这是 **粗体文本** 使用双星号

这是 __粗体文本__ 使用双下划线

这是 *斜体文本* 使用单星号

这是 _斜体文本_ 使用单下划线

这是 ~~删除线~~ 文本

这是 `行内代码` 示例

这是 **粗体和 `代码` 混合** 的例子

---

## 链接和图片

这是一个 [链接到 Anthropic](https://www.anthropic.com) 的例子

![这是一张示例图片](image.png)

---

## 列表

### 无序列表

- 第一项
- 第二项
  - 嵌套项 A
  - 嵌套项 B
- 第三项

* 使用星号的列表
+ 使用加号的列表

### 有序列表

1. 第一项
2. 第二项
3. 第三项
   1. 嵌套编号项
   2. 另一个嵌套项

### 任务列表

- [ ] 未完成的任务
- [x] 已完成的任务
- [ ] 另一个待办事项

---

## 代码块

```swift
func helloWorld() {
    print("Hello, PaperMD!")
    let greeting = "欢迎使用 PaperMD"
    return greeting
}
```

```javascript
function sayHello(name) {
    console.log(`Hello, ${name}!`);
    const greeting = `你好，${name}`;
    return greeting;
}
```

~~~
波浪线围栏的代码块
也支持高亮
~~~

---

## 引用块

> 这是一段引用文本
> 可以有多行

>> 嵌套引用的第二层

>>> 嵌套引用的第三层

> 引用中也可以有 **格式化** 和 `代码`

---

## 水平分割线

---

***

___

---

## HTML 标签支持

<div class="container">
    <p>这是一段 <strong>HTML</strong> 内容</p>
    <a href="https://example.com">链接</a>
</div>

---

## 组合示例

### 我的待办清单

- [x] 学习 Markdown 基础
- [ ] 熟悉 PaperMD 编辑器
- [ ] 写一篇技术文档

> 记得：**写作是思考的整理**

查看 [Markdown 官方指南](https://www.markdownguide.org) 了解更多！
