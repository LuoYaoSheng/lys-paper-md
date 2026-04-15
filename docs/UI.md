行，我们把 macOS v1 的技术选型“钉死”，以后不反复纠结（除非踩到明确的硬坑）。
macOS 技术选型结论（定版）
1) App 框架：AppKit + Document-based（NSDocument）
结论：用 AppKit 做主，走 NSDocument 架构。
为什么要定这个：
	•	你要的是“编辑器”，不是“普通应用”。NSDocument 天生适合：打开/保存/自动保存/版本/文件协调。
	•	原生文件体验（Finder 打开、拖拽、最近文件、冲突处理）更稳。
	•	后续上架、系统集成（Quick Look、Services）也更顺。
SwiftUI 可以用，但只当“壳”或设置页；核心编辑必须是 AppKit。

2) 编辑核心：TextKit 2（NSTextContentManager / NSTextLayoutManager / NSTextViewportLayoutController）
结论：主编辑器选 TextKit 2。
你追求“极致输入体验”，TextKit 2 更符合长期路线：
	•	更现代的文本布局与渲染架构（可控性更强，适合大文档、复杂排版）
	•	更适合你做“结构化渲染”（标题/代码块/引用等样式分层），并保持滚动性能
⚠️ 现实提醒（但不动摇结论）：
	•	TextKit 2 学习曲线更陡；一些传统做法和 TextKit 1 不一样
	•	但这正是“作品级编辑器”该走的路

3) 编辑视图：NSTextView（TextKit 2 模式）+ NSScrollView
结论：仍用 NSTextView 做输入承载，底层走 TextKit 2 管线。
原则：
	•	不 WebView
	•	不富文本编辑器套富文本（例如第三方 HTML 编辑器）
	•	NSTextView 是你“光标/IME/Undo”最稳的基座

4) 文档内部数据结构：Markdown 纯文本为源（source of truth）
结论：文件保存永远是 .md 纯文本；内部允许有解析结构，但不能反向污染源文件。
落地方式（建议定死）：
	•	rawText：真实文本（保存用）
	•	parseTree：增量解析后的结构（渲染用）
	•	渲染：用 attributes（NSAttributedString 属性）实现“所见即所得”的样式，但不改变用户输入的源文本语义
这能最大化保证：稳定、可预测、可撤销。

5) Markdown 解析：增量解析（Incremental）优先
v1 可以这么定：
	•	先做 行级增量：只重算受影响的段落/块（标题/列表/代码块）
	•	v2 再上更完整的 AST（或更细粒度增量）
关键点：
	•	解析不能阻塞输入线程
	•	输入时只做最轻量工作；重活放到后台，完成后再温柔更新样式（不抖、不跳光标）

6) Undo/Redo：NSUndoManager（系统级）
结论：所有结构化操作必须走 NSUndoManager。
要求定死：
	•	自动格式化（如 # → 标题样式）必须可撤销
	•	图片粘贴：落盘 + 插入链接 也必须作为一个可撤销动作组

7) 图片策略：落盘文件 + 相对路径
结论：统一落盘到 xxx.assets/，写相对路径。（你 PRD 里已经写了，这里把技术实现也定死）
实现要点：
	•	粘贴/拖拽 -> 生成文件名（时间戳+hash）-> 写入 assets -> 插入 `![](xxx.assets/...)`
	•	同时在编辑器里显示图片为“附件/inline image”（NSTextAttachment 或你自绘 attachment）

8) 导出：HTML（自渲染）+ PDF（系统打印管线）
结论：导出不走“截图流”，走系统级可控输出。
	•	HTML：你自己从 parseTree 生成（带主题 CSS）
	•	PDF：推荐走 NSPrintOperation（把排版内容渲染成可打印视图/布局，再打印到 PDF）
v1 不追求花哨，追求：一致、稳定、可重复。

9) UI 技术边界：核心编辑 AppKit；设置页 SwiftUI 可选
结论：
	•	Editor：100% AppKit
	•	Settings/About：SwiftUI OK（不影响编辑器内核）

最终“钉死”的技术栈清单（你可以直接写进仓库 README）
	•	语言：Swift
	•	UI：AppKit（主） + SwiftUI（仅设置页可选）
	•	文档架构：NSDocument / Document-based App
	•	编辑核心：TextKit 2 + NSTextView
	•	渲染策略：Markdown 源文本 + 增量解析 + 属性渲染（不改变源语义）
	•	Undo：NSUndoManager
	•	图片：落盘 assets + 相对路径 + inline attachment 显示
	•	导出：HTML 生成 + NSPrintOperation 输出 PDF

下一步我建议你立刻做的 3 件事（按顺序）
	1	工程骨架：Document-based App + 单窗口 + Toolbar + EditorTextView（空白也行）
	2	输入守护：IME/光标/撤销 的“最小正确性”测试用例（我可以给你一套测试清单）
	3	最小渲染：只做标题/代码块/引用三种样式的属性渲染，验证不卡、不抖、不跳光标
你想我接下来给你：
	•	A. macOS 工程目录与类/对象结构图（能直接开建），还是
	•	B. IME/光标/Undo 的验收测试清单（防止早期走偏）？
