# PaperMD 测试样板

当前这里先放**手工回归用的 Markdown fixture**，目的不是立刻搭完整 XCTest，而是先固定一份稳定样本，避免编辑器迭代时“看起来正常，实际高亮和输入行为已经回退”。

当前样板：

- [SyntaxHighlightingTest.md](./SyntaxHighlightingTest.md)

这份文件覆盖了当前编辑器最敏感的结构：

- ATX / Setext 标题
- 粗体 / 斜体 / 删除线 / 行内代码
- 链接 / 图片
- 无序 / 有序 / 任务列表
- 代码块
- 引用
- 分割线
- HTML 标签

当前阶段的使用方式很简单：

1. 用 `PaperMD` 打开 `SyntaxHighlightingTest.md`
2. 逐段确认高亮、列表、任务列表、代码块和引用显示是否异常
3. 用中文输入法在不同结构中输入
4. 验证 Enter / Tab / Backspace / Undo / Redo 没有明显回退

后续会再把这里推进成正式测试入口，但第一阶段先把 fixture 固定下来。
