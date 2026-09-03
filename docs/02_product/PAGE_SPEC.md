# PaperMD 页面交互规格说明

> 版本：v1.0-rebuild　日期：2026-09-02
> 事实来源：逆向分析报告（docs/01_reverse/REVERSE_ANALYSIS.md）+ 源码路径逐条核对
> 本文档约束 HTML 原型的实现行为（旧版原型已归位至 prototype/v0-old/app-prototype.html；V1 新版原型见 prototype/v1-new/app-prototype.html，其在本文规格基础上叠加 docs/06_review/PRODUCT_REVIEW.md 的 B 类优化）

---

## 一、全局交互约定

### 1.1 窗口约定（macOS 原生行为）

- 多窗口：⌘N 每次新建 Document+窗口；关闭最后窗口 App 不退出（AppDelegate L342-346）。
- 窗口恢复禁用（Info.plist NSDisableWindowRestoration=true）；重启后不还原窗口。
- 主窗口初始 800×600 主屏居中（Document.placeWindowOnMainScreen）。
- 面板类窗口（偏好/查找替换）单例复用（isReleasedWhenClosed=false），关闭仅隐藏语义。

### 1.2 菜单栏约定（7 菜单，来自 AppDelegate.fixMenuStructure，逐项快捷键）

| 菜单 | 项（快捷键） |
|------|--------------|
| PaperMD | About PaperMD｜Preferences… ⌘,｜Hide PaperMD ⌘H｜Hide Others ⌥⌘H｜Show All｜Quit PaperMD ⌘Q |
| File | New ⌘N｜Open… ⌘O｜Open Recent ▸（最近列表…+Clear Menu）｜Close ⌘W｜Save ⌘S｜Save As… ⇧⌘S｜Export ▸（Export to HTML… ⌃⌘E｜Export to PDF… ⌃⌘P） |
| Edit | Undo ⌘Z｜Redo ⇧⌘Z｜—｜Cut ⌘X｜Copy ⌘C｜Paste ⌘V｜Select All ⌘A｜—｜Find… ⌘F｜Find Next ⌘G｜Find Previous ⇧⌘G｜Replace ⌥⌘F｜—｜Show Spelling and Grammar ⌘:｜Check Document Now ⌘;｜—｜Transformations ▸（Make Upper Case ⌃⌘U｜Make Lower Case ⌃⌘L｜Capitalize ⌥⌘C）｜Jump to Selection ⌘J |
| View | Toggle Sidebar ⌃⌘O｜Toggle Focus Mode ⌃⌘F |
| Format | Bold ⌘B｜Italic ⌘I｜Code ⌘K｜Strikethrough ⌥⌘S｜—｜Heading 1 ⇧⌘1｜Heading 2 ⇧⌘2｜Heading 3 ⇧⌘3｜—｜Blockquote ⌥⌘>｜Code Block ⌥⌘C｜Insert Link ⇧⌘L |
| Window | Minimize ⌘M｜Zoom｜Bring All to Front |
| Help | PaperMD Help ⇧⌘? |

### 1.3 快捷键总表（代码事实，覆盖 README 未列项）

`⌘N/⌘O/⌘W/⌘S/⇧⌘S/⌘Q`（文件）；`⌘Z/⇧⌘Z/⌘X/⌘C/⌘V/⌘A`（编辑）；`⌘F/⌘G/⇧⌘G/⌥⌘F`（查找）；`⌘:/⌘;/⌃⌘U/⌃⌘L/⌥⌘C(大写)/⌘J`（Edit 附属）；`⌃⌘O(侧栏)/⌃⌘F(专注)`（视图）；`⌘B/⌘I/⌘K/⌥⌘S(删除线)/⇧⌘1-3(标题)/⌥⌘>(引用)/⌥⌘C(代码块)/⇧⌘L(链接)`（格式）；`⌃⌘E/⌃⌘P`（导出）；`⌘,`（偏好）；`⌘H/⌥⌘H/⌘M/⌘Q`（系统）。注意 `⌥⌘C` 在 Transformations=Capitalize、在 Format=Code Block，同键双义（分属不同菜单，均为真实代码事实）。

### 1.4 编辑器键位约定（MarkdownTextView.keyDown）

- Enter：列表续行/终止（见 PAGE004）。
- Tab / ⇧Tab：列表行缩进 ±2 空格（⇧Tab 遇行首 tab 删 1 个）。
- Backspace：空列表项 marker 后→删行合并。
- ⌘ 组合键不拦截（交菜单）；IME marked text 期间一切拦截放行。

### 1.5 状态与反馈约定

- 未保存：标题栏"已编辑"标记（NSDocument 机制）。
- 自动保存：3 秒静默后静默落盘（无 toast，旧版事实；原型以评审用 toast 呈现该不可见行为）。
- 失败反馈：旧版多数失败仅 DebugLog（导出写失败/图片写失败/自动保存失败）；原型在评审面板呈现这些静默失败的可视化。
- 禁用规则：Bold/Italic/Code/Strikethrough/Link 需选区；Undo/Redo 按 canUndo/canRedo。

### 1.6 主题与颜色约定（MarkdownTheme）

- 三态 Light/Dark/System；编辑器色板：heading/code=蓝/粉、link=蓝、image=紫、listMarker=橙、quote=青、meta=次要标签色、hr=分隔线色、htmlTag=棕、task=灰（选中 systemGreen）、图片行背景=紫 8%（暗 15%）。
- 标题字号阶梯 [28,24,20,18,17,16]（H1-H6，基于基础字号固定的绝对值）；行内码/代码块=等宽（基础-2）。

---

## 二、页面 11 维度规格

### PAGE001 主编辑窗口

| 维度 | 规格 |
|------|------|
| PAGE-ID | PAGE001 |
| 页面目标 | 单文档编辑完整容器（PRD §6.PAGE001） |
| 进入条件 | 启动 / ⌘N / ⌘O / Dock 重开 / 全窗口关闭后再激活 |
| 页面结构 | 标题栏(红绿灯+标题+未编辑标记) → 工具栏(PAGE006) → NSSplitView[大纲侧栏(PAGE003) 200pt ｜ NSScrollView 编辑区(PAGE004)] → 状态栏(PAGE005, 28pt) |
| 组件列表 | NSWindow(.titled/.closable/.miniaturizable/.resizable)、NSToolbar、NSSplitView(.thin 竖向)、NSScrollView、StatusBar |
| 按钮列表 | 窗口：关闭(⌘W)/最小化(⌘M)/缩放（系统红绿灯） |
| 按钮行为 | 关闭→有未保存时系统弹保存询问→确认保存/取消/不保存；最小化/缩放系统行为 |
| 状态列表 | 干净态（标题无标记）/ 未保存态（标题"已编辑"）/ 专注态（见 PAGE007） |
| 跳转关系 | 关闭→App 驻留（无窗口）；⌘, → PAGE008；⌘F → PAGE009；⌘O → PAGE010；⌘S(无文件) → PAGE011；⌃⌘E → PAGE012；⌃⌘P → PAGE013；About → PAGE014 |
| 异常处理 | openEditorWindow 失败仅日志；打开文件解码失败→空文档 |
| 数据展示规则 | 标题=displayName 或 "Untitled"；新文档预填欢迎文本 |

### PAGE002 应用菜单栏

| 维度 | 规格 |
|------|------|
| PAGE-ID | PAGE002 |
| 页面目标 | 全量命令入口、全键盘可达（PRD §6.PAGE002） |
| 进入条件 | App 前台即常驻 |
| 页面结构 | 7 顶级菜单：PaperMD/File/Edit/View/Format/Window/Help（结构见全局约定 1.2） |
| 组件列表 | NSMenu×7 + 子菜单×3（Open Recent/Export/Transformations） |
| 按钮列表 | 见全局约定 1.2 全表（约 40 项） |
| 按钮行为 | 每项→响应链→对应 F 功能（见 PRD §5）；Open Recent 项→直接打开该 URL |
| 状态列表 | 项级启用/禁用（F058 规则）；Open Recent 空时仅 Clear Menu |
| 跳转关系 | Preferences…→PAGE008；Find…→PAGE009；Open…→PAGE010；Save…→PAGE011；Export…→PAGE012/013；About→PAGE014 |
| 异常处理 | 最近文档打开失败→DebugLog；Help 无 Help book（行为【未知】） |
| 数据展示规则 | 快捷键右对齐显示；最近项 tooltip=完整路径 |

### PAGE003 大纲侧栏

| 维度 | 规格 |
|------|------|
| PAGE-ID | PAGE003 |
| 页面目标 | 标题结构导航（PRD §6.PAGE003，F030） |
| 进入条件 | 主窗口显示且侧栏未折叠（⌃⌘O 切换；专注模式强制隐藏） |
| 页面结构 | NSScrollView+NSTableView（单列无表头行距 4pt） |
| 组件列表 | 大纲行（缩进 = 16×(level-1)pt；字体 H1 bold14/H2 bold13/其他 13） |
| 按钮列表 | 行（单击/双击同效跳转） |
| 按钮行为 | 行→onHeadingSelected(lineNumber)→编辑区选中原行 scrollRangeToVisible→0.1s 后光标收缩行首 |
| 状态列表 | 选中高亮（regular）；空文档=空列表 |
| 跳转关系 | 跳转后焦点保持在编辑区（不影响编辑焦点，PRD 5.5） |
| 异常处理 | 行号越界忽略；无标题空态 |
| 数据展示规则 | 数据源 MarkdownParser.parseHeadings（ATX1-6+Setext1/2；空标题过滤；level 钳制 ≤6） |

### PAGE004 Markdown 编辑区

| 维度 | 规格 |
|------|------|
| PAGE-ID | PAGE004 |
| 页面目标 | P0 输入体验承载（PRD §6.PAGE004，F013-F018/F032-F048） |
| 进入条件 | 主窗口存在；窗口 key 时自动 firstResponder |
| 页面结构 | NSScrollView(纵向滚动) 内 NSTextView；字体=系统字(偏好字号)；背景 textBackgroundColor |
| 组件列表 | 文本区（accessibility id=editor-text-view）、光标、选区 |
| 按钮列表 | 无按钮（键位见全局约定 1.4；格式化命令入口在 PAGE002/006） |
| 按钮行为 | Enter：列表行且行尾→非空项插 `\n+marker`（无序同符号/有序 n+1/任务 `- [ ] `），空项删 marker 后默认换行；Tab/⇧Tab：列表行首 ±2 空格；Backspace：空项 marker 后→删本行+前换行；⌘V：图片→落盘插 `![](path)`，否则纯文本替换选区光标移末；拖入图片→落点插入；IME 期间→全部放行仅统计刷新 |
| 状态列表 | 普通 / IME 组合（跳过重排版）/ isApplyingFormatting 防重入 |
| 跳转关系 | 与大纲/状态栏/文档标题联动（数据单向：编辑区→三者） |
| 异常处理 | 图片写盘失败不插入；解码失败空文档；越界范围 safeRange 钳制 |
| 数据展示规则 | 行级增量高亮（F040/F041 全清单）；行内代码区间内禁用其他行内格式化；代码块范围自动扩展（前向 ≤100 行） |

### PAGE005 状态栏

| 维度 | 规格 |
|------|------|
| PAGE-ID | PAGE005 |
| 页面目标 | 写作统计（PRD §6.PAGE005，F031） |
| 进入条件 | 主窗口显示且非专注模式 |
| 页面结构 | 28pt 横条：words｜分隔｜characters｜分隔｜min read（间距 20，11pt 次要色） |
| 组件列表 | 3 个只读 NSTextField + 2 竖线分隔 |
| 按钮列表 | 无 |
| 按钮行为 | 无交互 |
| 状态列表 | 空文档态（0 words/0 characters/1 min read——下限 1 为旧版事实） |
| 跳转关系 | 无 |
| 异常处理 | 无 |
| 数据展示规则 | 词=空白切分非空段数；字符=text.count；阅读=max(1,⌊词/200⌋) |

### PAGE006 工具栏

| 维度 | 规格 |
|------|------|
| PAGE-ID | PAGE006 |
| 页面目标 | 高频格式化一键（PRD §6.PAGE006，F057） |
| 进入条件 | 主窗口显示且非专注模式 |
| 页面结构 | `[Sidebar]｜…弹性空隙…[Bold][Italic][Code][Heading][Quote][CodeBlock]`（iconOnly） |
| 组件列表 | 7 个 NSToolbarItem + 分隔符 + 弹性空隙（SF Symbol 图标） |
| 按钮列表 | Sidebar / Bold(⌘B) / Italic(⌘I) / Code / Heading(H1) / Quote / Code Block |
| 按钮行为 | 与同名菜单命令完全同源（转发 EditorView）；Sidebar→侧栏切换 |
| 状态列表 | Bold/Italic/Code 无选区时禁用；Heading/Quote/CodeBlock/Sidebar 恒可用 |
| 跳转关系 | 无独立窗口 |
| 异常处理 | 无 |
| 数据展示规则 | tooltip 含快捷键（Bold (⌘B) 等）；不可自定义不保存配置 |

### PAGE007 专注模式（主窗口变体）

| 维度 | 规格 |
|------|------|
| PAGE-ID | PAGE007 |
| 页面目标 | 免打扰（PRD §6.PAGE007，F029） |
| 进入条件 | ⌃⌘F 触发切换 |
| 页面结构 | 仅编辑区满宽（0.25s 动画折叠侧栏 200→0） |
| 组件列表 | 编辑区（PAGE004 复用） |
| 按钮列表 | 无附加按钮（⌃⌘F 再切回） |
| 按钮行为 | 进入：sidebar 折叠+隐藏、statusBar 隐藏、toolbar 隐藏；退出全部还原 |
| 状态列表 | 二态（isFocusMode） |
| 跳转关系 | 无 |
| 异常处理 | 无 |
| 数据展示规则 | 编辑内容与高亮不变 |

### PAGE008 偏好设置窗口

| 维度 | 规格 |
|------|------|
| PAGE-ID | PAGE008 |
| 页面目标 | 全局偏好（PRD §6.PAGE008，F049-F052） |
| 进入条件 | ⌘, |
| 页面结构 | 450×300 标题 "Preferences"；三分区纵排（边距 20-24，节间距 16）：Editor Font Size / Appearance / General |
| 组件列表 | 字号 NSPopUpButton(12/13/14/15/16/17/18/20/22/24 pt)、主题 NSPopUpButton(Light/Dark/System)、自动保存复选框("Automatically save documents") |
| 按钮列表 | 窗口关闭（红绿灯） |
| 按钮行为 | 弹出选值→即写 UserDefaults→apply()（套 NSAppearance+广播 preferencesChanged→全文重排版光标保持）；复选框→切换 autosaveEnabled |
| 状态列表 | 当前值=启动时 loadPreferences 选中 |
| 跳转关系 | 关闭→返回主窗口（设置已生效） |
| 异常处理 | 无（UserDefaults 托管） |
| 数据展示规则 | 分区标题 bold13；启动仅 applyLaunchSettings 不广播 |

### PAGE009 查找替换面板

| 维度 | 规格 |
|------|------|
| PAGE-ID | PAGE009 |
| 页面目标 | 检索与替换（PRD §6.PAGE009，F019-F023） |
| 进入条件 | ⌘F（编辑窗口存在时） |
| 页面结构 | 420×160 标题 "Find and Replace"：Find 行 / Replace 行 / 正则复选框 / 按钮行(Find Next・Replace・Replace All) |
| 组件列表 | 2 输入框（标签宽 60）+ 复选框 + 3 按钮 |
| 按钮列表 | Find Next / Replace / Replace All |
| 按钮行为 | Find Next：空忽略；选区后起搜命中选中滚动；到尾 start>0 回绕。Replace：无选区先全找；替换后自动 Find Next。Replace All：整文替换（正则可选），直接重置文本 |
| 状态列表 | 普通/正则两模式（复选框） |
| 跳转关系 | 目标始终为主编辑区选区 |
| 异常处理 | 空查询忽略；无命中无提示；正则非法静默保持原文；Replace All 不入 undo+选区重置（旧版事实） |
| 数据展示规则 | 命中以编辑区选区（蓝色高亮）呈现 |

### PAGE010 打开文件面板

| 维度 | 规格 |
|------|------|
| PAGE-ID | PAGE010 |
| 页面目标 | 打开本地文档（PRD §6.PAGE010，F003/F004） |
| 进入条件 | ⌘O / Open Recent 项 |
| 页面结构 | 系统 NSOpenPanel（沙盒用户授权） |
| 组件列表 | 系统文件浏览器 |
| 按钮列表 | 打开/取消（系统） |
| 按钮行为 | 确认→Document.read(UTF-8)→载入→prepareForDisplay→自动保存计时 |
| 状态列表 | 无记忆态（窗口恢复禁用） |
| 跳转关系 | 取消→返回；确认→文档在主窗口呈现 |
| 异常处理 | 解码失败→空文档不崩溃；最近项失效→日志 |
| 数据展示规则 | 可选类型 .md/.markdown（Info.plist 注册 net.textility.markdown） |

### PAGE011 保存/另存为面板

| 维度 | 规格 |
|------|------|
| PAGE-ID | PAGE011 |
| 页面目标 | 落盘纯 Markdown（PRD §6.PAGE011，F006/F007） |
| 进入条件 | ⌘S（无 fileURL 时）/ ⇧⌘S |
| 页面结构 | 系统 NSSavePanel 定制 |
| 组件列表 | 名称输入+目录选择+扩展切换 |
| 按钮列表 | 保存/取消（系统） |
| 按钮行为 | 确认→writeSafely（先迁移 pending 图片→UTF-8 写 textView.string） |
| 状态列表 | 默认名：Untitled→`untitled.md`；displayName 无 .md→补 .md |
| 跳转关系 | 取消→返回编辑（保持未保存态） |
| 异常处理 | 写失败→系统标准错误反馈 |
| 数据展示规则 | allowedContentTypes=[.plainText]+allowsOtherFileTypes；可建目录 |

### PAGE012 导出 HTML 面板

| 维度 | 规格 |
|------|------|
| PAGE-ID | PAGE012 |
| 页面目标 | HTML 交付（PRD §6.PAGE012，F009） |
| 进入条件 | ⌃⌘E |
| 页面结构 | 系统 NSSavePanel（标题 "Export to HTML"） |
| 组件列表 | 同 PAGE011 |
| 按钮列表 | 导出/取消 |
| 按钮行为 | 确认→ExportHelper.convertToHTML（统一解析+当前主题 CSS）→UTF-8 原子写 |
| 状态列表 | 默认名 `{文档名|document}.html` |
| 跳转关系 | 取消→无副作用 |
| 异常处理 | 写失败仅 DebugLog（无用户提示，旧版事实） |
| 数据展示规则 | 类型限定 .html |

### PAGE013 导出 PDF 打印面板

| 维度 | 规格 |
|------|------|
| PAGE-ID | PAGE013 |
| 页面目标 | PDF 交付（PRD §6.PAGE013，F010） |
| 进入条件 | ⌃⌘P |
| 页面结构 | PrintableMarkdownView(612×792, WKWebView 渲染导出 HTML)→NSPrintOperation→系统打印面板（横向 fit/纵向自动分页） |
| 组件列表 | 系统打印控件（打印机/份数/PDF 下拉） |
| 按钮列表 | 打印/取消（系统） |
| 按钮行为 | 用户经系统"存储为 PDF"完成输出 |
| 状态列表 | 无 |
| 跳转关系 | 取消→无副作用 |
| 异常处理 | WKWebView 异步加载与打印时序未等待【未知】；无目录功能（旧文档矛盾以代码为准） |
| 数据展示规则 | 内容与 HTML 导出同源同主题 |

### PAGE014 关于面板

| 维度 | 规格 |
|------|------|
| PAGE-ID | PAGE014 |
| 页面目标 | 应用信息（F054） |
| 进入条件 | App 菜单 → About PaperMD |
| 页面结构 | 系统标准 About（图标/名称/版本 1.0） |
| 组件列表 | 系统生成 |
| 按钮列表 | 关闭 |
| 按钮行为 | 系统行为 |
| 状态列表 / 跳转 / 异常 / 数据 | 系统托管；版本读自 bundle（CFBundleShortVersionString=1.0） |

---

## 三、六项特检矩阵（逐页）

> ✔=页面存在该场景且已定义行为；—=不适用；⚠=旧版静默/缺失，原型需在评审面板可视化标注

| 页面 | ①空文档/空数据 | ②加载中 | ③错误 | ④权限（文件访问） | ⑤文件读写异常 | ⑥用户取消 |
|------|:---:|:---:|:---:|:---:|:---:|:---:|
| PAGE001 主窗口 | ✔ 新文档预填欢迎文本；空文档 0 词 | ✔ 打开大文档时高亮/大纲计算在主线程调度（旧版无显式 loading——原型以加载态呈现打开过程） | ⚠ 解码失败空文档兜底 | ✔ 沙盒仅用户选择文件可写 | ⚠ 写失败系统反馈/日志 | ✔ 关闭询问可取消 |
| PAGE002 菜单栏 | ✔ 无选区时格式项禁用 | — | ⚠ 最近文档失效仅日志 | — | — | — |
| PAGE003 大纲 | ✔ 无标题=空列表（空态文案旧版无——原型补空态示意） | ✔ 随文本异步刷新 | — | — | — | — |
| PAGE004 编辑区 | ✔ 空文档可立即打字聚焦 | ✔ IME 期间跳过重排（防卡顿机制） | ⚠ 图片写盘失败静默 | ✔ 拖入需可读文件 | ⚠ assets 创建失败静默 | ✔ 拖拽可取消 |
| PAGE005 状态栏 | ✔ 0/0/1 显示 | — | — | — | — | — |
| PAGE006 工具栏 | ✔ 无选区禁用三项 | — | — | — | — | — |
| PAGE007 专注模式 | ✔ 空文档可进专注 | — | — | — | — | ✔ 可随时切回 |
| PAGE008 偏好 | ✔ 默认值 16/system/true | — | — | — | — | ✔ 关闭=已即时生效不回滚 |
| PAGE009 查找替换 | ✔ 空查询忽略 | — | ⚠ 无命中/正则非法均静默 | — | — | ✔ 关闭面板无副作用 |
| PAGE010 打开面板 | ✔ 空目录系统态 | ✔ 系统面板自身 | ⚠ 解码失败空文档 | ✔ 沙盒授权模型 | ✔ 选择不可读文件系统报错 | ✔ 取消返回 |
| PAGE011 保存面板 | ✔ 默认名兜底 untitled.md | — | ✔ 写失败系统反馈 | ✔ 沙盒授权目录 | ✔ 磁盘满/只读系统报错 | ✔ 取消保持未保存 |
| PAGE012 导出 HTML | ✔ 空文档导出空结构 HTML | — | ⚠ 写失败仅日志 | ✔ 沙盒授权目录 | ⚠ 同左 | ✔ 取消无副作用 |
| PAGE013 导出 PDF | ✔ 空文档可导出 | ✔ WKWebView 异步渲染 | ⚠ 渲染时序未等待 | — | ✔ 打印失败系统反馈 | ✔ 取消无副作用 |
| PAGE014 关于 | — | — | — | — | — | ✔ 关闭 |

---

## 四、HTML 原型必须呈现的状态库（五态映射）

| 原型状态 | 触发场景 | 对应页面/功能 |
|----------|----------|----------------|
| 加载态 | 打开大文档时窗口 loading 遮罩 | PAGE001/PAGE004/F003 |
| 成功态 | 默认样例文档全部功能正常 | 全部 |
| 失败态 | 打开损坏文件（解码失败→空文档+评审提示）；导出写失败（评审提示旧版静默） | PAGE010/PAGE012 |
| 空数据态 | 新建空白文档（欢迎文本）、无标题空大纲、0/0/1 状态栏 | PAGE001/PAGE003/PAGE005 |
| 异常态 | IME 演示（组合中禁重排提示）、磁盘只读保存失败、图片写盘失败 | PAGE004/PAGE011/F014 |
