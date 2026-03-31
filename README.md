<div align="center">

  ## lys IoT DevTools

  **PaperMD**

  原生 macOS Markdown 编辑器，极致输入体验

  **作者**: 罗耀生 (寺西)

  [![lys IoT DevTools](https://img.shields.io/badge/lys-IoT--DevTools-blue)](https://gitee.com/luoyaosheng)
  [![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

</div>

---

## 简介

PaperMD 是一款专为 macOS 设计的原生 Markdown 编辑器，专注于极致的输入体验。适用于长文写作、文档编写和技术写作。

## 核心特性

- **原生 macOS 应用**：使用 AppKit 构建，性能和体验都是原生的
- **实时预览**：输入时实时 Markdown 语法高亮
- **智能编辑**：自动列表续行、Tab 缩进、智能列表项终止
- **大纲视图**：从标题自动生成目录，方便导航
- **专注模式**：隐藏干扰，专注于写作
- **全键盘支持**：所有操作都有快捷键
- **纯文本粘贴**：从外部粘贴时自动去除格式

## 快捷键

### 文件操作
| 快捷键 | 操作 |
|--------|------|
| `⌘N` | 新建文档 |
| `⌘O` | 打开… |
| `⌘W` | 关闭窗口 |
| `⌘S` | 保存 |
| `⌘⇧S` | 另存为… |
| `⌘Q` | 退出 |

### 编辑操作
| 快捷键 | 操作 |
|--------|------|
| `⌘Z` | 撤销 |
| `⇧⌘Z` | 重做 |
| `⌘X` | 剪切 |
| `⌘C` | 复制 |
| `⌘V` | 粘贴 (纯文本) |
| `⌘A` | 全选 |

### 格式化
| 快捷键 | 操作 |
|--------|------|
| `⌘B` | 粗体 |
| `⌘I` | 斜体 |
| `⌘K` | 行内代码 |
| `⇧⌘1` | 一级标题 |
| `⇧⌘2` | 二级标题 |
| `⇧⌘3` | 三级标题 |

## 智能编辑功能

### 列表续行
在列表项末尾按 Enter，自动创建新列表项：
- 无序列表 (`- `, `* `, `+ `) 继续相同标记
- 有序列表 (`1. `, `2. ` 等) 继续递增数字
- 任务列表 (`- [ ] `) 继续未勾选项
- 在空列表项按 Enter 终止列表

### Tab 缩进
- 按 `Tab` 缩进列表项（增加 2 个空格）
- 按 `⇧Tab` 取消缩进（减少 2 个空格）

## 技术栈

| 组件 | 技术 |
|------|------|
| 语言 | Swift |
| UI 框架 | AppKit |
| 文档架构 | NSDocument |
| 编辑引擎 | NSTextView + NSTextStorage |
| 撤销系统 | NSUndoManager |

## 系统要求

- macOS 12.0 或更高版本
- Xcode 14.0 或更高版本（从源码构建）

## 构建方法

```bash
git clone https://gitee.com/luoyaosheng/lys-paper-md.git
cd lys-paper-md
open PaperMD.xcodeproj
```

然后在 Xcode 中构建并运行。

## 开发理念

**输入体验优先** - 我们宁愿慢一点，也不允许一次输入体验上的妥协。

- 光标位置必须符合用户预期，永远不会因为渲染而跳转
- 自动格式化绝不能移动光标位置
- 中文输入法状态下，不进行布局重建或结构转换
- 每个结构变更都必须可撤销

## 许可证

MIT License

---

<div align="center">

  **lys IoT DevTools - 从硬件到云端的开源 IoT 开发工具链**

</div>
