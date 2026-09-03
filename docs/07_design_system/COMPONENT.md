# PaperMD Design System — Components（P5）

> 版本：v1.0　日期：2026-09-02
> 原则：**业务组件优先**（先编辑器/查找面板/偏好窗格等，后通用原子组件）；每组件给「组件记录表」；来源=旧项目源码文件；V1 变化=P4 B 类优化在组件上的落点。
> 通用原子控件（按钮/输入框/弹出菜单/复选框）由 AppKit 系统托管，本文件不重复定义样式，仅记录使用约束。

---

## 组件总览（10 业务组件 + 3 原型层组件）

| 编号 | 组件 | 类型 | 来源文件 | V1 变化 |
|------|------|------|----------|---------|
| CP-01 | 主窗口框架 | Component | Document.swift / WindowController.swift | — |
| CP-02 | 菜单栏 | Component | AppDelegate.swift L89-305 | B1/B2/B5 |
| CP-03 | 工具栏 | Component | WindowController.swift L58-195 | B1 |
| CP-04 | 大纲侧栏 | Component | OutlineView.swift | B8 |
| CP-05 | Markdown 编辑器视图 | Component | EditorView.swift / MarkdownTextView.swift / MarkdownFormatter.swift | B3/B4/B5 |
| CP-06 | 状态栏 | Component | StatusBar.swift | B7 |
| CP-07 | 查找替换面板 | Component | SearchReplaceController.swift / TextSearch.swift | B2/B3/B6 |
| CP-08 | 偏好窗格 | Component | PreferencesWindowController.swift | D2（标题措辞） |
| CP-09 | 系统面板适配组 | Component | AppDelegate / Document / ExportHelper | B5 |
| CP-10 | 专注模式视图态 | Component（状态变体） | EditorView L358-381 | — |
| CP-11 | 反馈提示组（toast/alert/面板状态行） | Component（V1 新增呈现） | 无旧源码（旧版静默） | B5/B6 载体 |
| CP-12 | 撤销分组（图片类） | Module 挂载 | ImageHandler.swift L203-234 | B3 扩展至 Replace All |
| CP-13 | macOS 窗口画框+评审面板 | 原型层组件 | prototype/v0-old/app-prototype.html | v1-new 复用骨架 |

---

## CP-05 Markdown 编辑器视图（核心组件）

### 组件记录表

| 维度 | 规格 | 来源 |
|------|------|------|
| 组件 ID | CP-05 | — |
| 职责 | styled-source 编辑：标记可见 + 属性叠加高亮 + 智能键 + IME 保护 | CLAUDE.md "Edit model" |
| 结构 | NSScrollView(仅纵向) → NSTextView(NSTextStorage+NSLayoutManager+NSTextContainer) | EditorView.swift L52-70 |
| 尺寸 | 宽随窗口（减 200pt 侧栏，最小 100pt）；高无限增长 | EditorView L64-66、L119 |
| 字体 | --fs-base（默认 16）系统字；等宽 --fs-mono | EditorView L126、Formatter L54 |
| 背景 | --bg-editor（textBackgroundColor） | EditorView L129 |
| 状态机 | 普通 → IME 组合（跳过重排仅统计）→ 格式化中（isApplyingFormatting 防重入） | EditorView L217-235、L48 |
| 输入 | 键盘（Enter/Tab/⇧Tab/Backspace 拦截表见 patterns.md §2）、拖拽（png/tiff/fileURL/string） | MarkdownTextView L126-172、L21-28 |
| 输出 | NSTextStorage.string（唯一事实源）→ 大纲/统计/保存 | Document.swift L129-137 |
| 可访问性 | identifier=editor-text-view；label="Markdown Editor" | EditorView L143-144 |
| 禁用/边界 | reapplyFormatting 空文档直接返回；safeRange 钳制 | EditorView L265、Formatter L839-844 |

### V1 变化（B3/B4/B5）

- **B4**：高亮引擎新增 tableRow/tableSeparator 分支——tableRow 用 `--syntax-quote` 系浅着色（行内格式照常），tableSeparator 用 `--syntax-meta` 弱化；注明旧版无表格着色。
- **B3**：Replace All 改为撤销组包裹的 replaceCharacters（不再整串重置），视口保持。
- **B5**：图片写盘失败 → CP-11 toast「图片保存失败：{路径}（旧版仅日志）」。

---

## CP-07 查找替换面板

### 组件记录表

| 维度 | 规格 | 来源 |
|------|------|------|
| 组件 ID | CP-07 | — |
| 窗口 | 420×160，标题 "Find and Replace"，单例（isReleasedWhenClosed=false） | SearchReplaceController L18-26 |
| 布局 | 垂直栈：边距 16、行距 10；Find 行/Replace 行（标签宽 60）/正则复选框/按钮行（距 8） | L35-66 |
| 控件 | 2 输入框 + "Use Regular Expression" 复选框 + Find Next / Replace / Replace All 三按钮 | L41-56 |
| 行为-Find Next | 空忽略；选区后起搜；命中选中+滚动；到尾 start>0 回绕 | L82-98 |
| 行为-Replace | 无选区先全找；替换后自动 Find Next | L114-138 |
| 行为-Replace All | 旧：整串重置不入 undo | L140-152 |
| 目标绑定 | weak targetTextView（keyWindow 编辑区，每次 ⌘F 重建绑定） | L15、AppDelegate L359-368 |

### V1 变化（B2/B3/B6）

- **B6**：新增状态行（面板底部）：`n/m 命中 · 已替换 k 处 · 已回绕`；无命中显示「无命中」；正则非法显示「正则表达式无效」（旧版静默）。
- **B3**：Replace All 注册撤销组 + 保持视口 + 状态行报告替换数；按钮 tooltip 注明「V1：可撤销（旧版不可）」。
- **B2**：⌘G/⇧⌘G/⌥⌘F 菜单项直接驱动本面板（菜单→面板动作映射，见 patterns.md §3）。
- Esc 关闭面板（macOS 面板惯例，V1 显式定义）。

---

## CP-02 菜单栏 / CP-03 工具栏

### 组件记录表（合并：两入口同源）

| 维度 | 菜单栏 CP-02 | 工具栏 CP-03 |
|------|--------------|--------------|
| 结构 | 7 顶级菜单 + 3 子菜单（Open Recent/Export/Transformations），程序化重建 | 7 功能项 + separator + flexibleSpace，iconOnly |
| 来源 | AppDelegate L89-305 | WindowController L58-195 |
| 快捷键 | 见 patterns.md §4 全集 | tooltip 含快捷键（如 "Bold (⌘B)"） |
| 禁用规则 | 格式化 5 项需选区（F058）；Undo/Redo 按 canUndo/canRedo | 同源（validateMenuItem 转发 EditorView） |
| 图标 | 无（纯文字+快捷键右对齐） | SF Symbols 7 枚（见 assets.md） |

### V1 变化（B1/B2/B5）

- **B1**：Format 菜单 Heading 组扩为 1-6（⇧⌘1~⇧⌘6）；工具栏 Heading 按钮改下拉（长按/点击展开 H1-H6，默认动作仍 H1 保持肌肉记忆）。
- **B2**：Edit 菜单 Find Next/Find Previous/Replace 三项绑定自研面板动作（旧版绑定系统 performFindPanelAction 未联动——注明）。
- **B5**：导出失败/最近文档打开失败增加 alert（旧版仅日志）。

---

## CP-04 大纲侧栏 / CP-06 状态栏

### 组件记录表（合并：信息展示双件套）

| 维度 | 大纲侧栏 CP-04 | 状态栏 CP-06 |
|------|----------------|--------------|
| 布局 | 200pt 左栏；NSTableView 单列无表头；行距 4pt | 28pt 顶部横条；边距 12；间距 20；分隔线 1pt |
| 字体 | H1 bold14 / H2 bold13 / 其余 13；缩进 16×(level−1)+4 | 11pt secondaryLabel |
| 数据 | parseHeadings（ATX1-6+Setext1/2，空标题过滤） | DocumentStats：词=空白切分非空段、字符=text.count、阅读=max(1,⌊词/200⌋) |
| 交互 | 单击/双击行 → 跳转+0.1s 光标收缩 | 无交互 |
| 背景 | --bg-control | --bg-control |
| 来源 | OutlineView.swift | StatusBar.swift L10-128 |

### V1 变化（B7/B8）

- **B8**：大纲空态显示「暂无标题 · 以 # 开始的行将出现在这里」（旧版纯空列表）。
- **B7**：0 词显示 "0 min read"（旧版显示 1——怪癖修复并注明）。

---

## CP-01 主窗口框架 / CP-10 专注模式 / CP-08 偏好窗格 / CP-09 系统面板组

| 维度 | 规格 | 来源 |
|------|------|------|
| CP-01 主窗口 | 800×600 主屏居中；title=displayName/"Untitled"；未保存「已编辑」点（updateChangeCount）；红绿灯三键 | Document L63-123、EditorView L219 |
| CP-10 专注模式 | 三隐藏（侧栏 0.25s 折叠/状态栏/工具栏）二态切换 | EditorView L358-381、WindowController L267-271 |
| CP-08 偏好窗格 | 450×300；三分区（Editor Font Size 十档弹出/Appearance 三态/自动保存复选）；即时生效无确定按钮 | PreferencesWindowController L14-224 |
| CP-09 系统面板组 | NSOpenPanel（⌘O）/NSSavePanel（⌘S/⇧⌘S/⌃⌘E，默认名补扩展名）/NSPrintOperation（⌃⌘P，WKWebView 612×792）/标准 About | AppDelegate L377-411、Document L213-238、ExportHelper L37-61 |

V1 变化：CP-08 标题按 macOS 13+ 惯例显示 "Settings"（注明旧版 "Preferences"，D2）；CP-09 导出/打开失败增加可见反馈（B5）。CP-01/CP-10 照旧。

---

## CP-11 反馈提示组（V1 新增呈现，承载 B5/B6）

> 旧版无任何用户可见反馈组件（全部 DebugLog）——本组件是 V1 原型对 B5 的载体，样式全部复用既有 token，不新增语义 token。

| 子件 | 触发 | 呈现 | token |
|------|------|------|-------|
| toast（自动保存成功/失败） | 3 秒静默落盘后（旧版无提示） | 编辑区右上角浮层 2s 自动消失 | --bg-control / --fg-secondary / --separator |
| alert（导出失败/打开损坏文件/最近文档失效） | 写盘 catch / 解码失败 / open error | 模态对话框（macOS 风格画框）+「查看详情」 | 复用模态 token |
| 面板状态行（查找计数/正则错误/回绕） | CP-07 内 | 面板底部 11pt secondaryLabel 行 | --fg-secondary |
| 标题栏已编辑点 | updateChangeCount（旧版已有） | 标题左侧 ● | 旧版系统机制 |

---

## CP-12 撤销分组 / CP-13 原型层组件

- **CP-12**：旧版仅图片插入有文件级撤销组（ImageInsertUndoHandler：文本删除+文件删除成对；重做成对恢复，ImageHandler L203-234）。V1（B3）将 Replace All 纳入同模式的文本级撤销组（无文件副作用）。
- **CP-13**：原型层组件——macOS 窗口画框（红绿灯/标题栏/阴影/圆角 10px）+ 右侧评审面板（页面导航/五态场景/标注开关）。v1-new 复用 v0 骨架，评审面板增加「B 类优化对照」区与 C 类留档区。

---

## 组件-功能映射（供 V1 验收追溯）

| 组件 | 承载功能 ID |
|------|-------------|
| CP-01 | F001 F002 F003 F005 F053 |
| CP-02 | F004 F024 F025 F026 F027 F055 F056 F058（+B1/B2 入口） |
| CP-03 | F028 F032-F034 F036-F038 F057 |
| CP-04 | F028 F030 |
| CP-05 | F011 F013-F018 F032-F048 |
| CP-06 | F031 |
| CP-07 | F019-F023（+B2/B3/B6） |
| CP-08 | F008 F049-F052 |
| CP-09 | F006 F007 F009 F010 F054 |
| CP-10 | F029 |
| CP-11 | B5/B6 载体（F008/F009/F014/F019/F023/F003 的失败反馈） |
| CP-12 | F011 F018（+B3） |
