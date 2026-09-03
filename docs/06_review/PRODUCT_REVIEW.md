# PaperMD 产品体验审查报告（P4）

> 版本：v1.0　日期：2026-09-02
> 审查对象：旧 App 全量功能与页面（基准=docs/01_reverse/REVERSE_ANALYSIS.md 逆向事实模型 + 源码复核）
> 审查方法：以「功能→入口→流程→反馈」四步走查 60 项功能（F001-F060）与 14 页面（PAGE001-014），所有发现均标注源码来源；本报告不改任何源码。
> 分级处置定义：
> - **A = 文档勘误**：昨晚产物文档存在事实性错误或路径失效，直接修改并在 §6 登记；
> - **B = 体验优化**：进入 V1 新版原型落地（prototype/v1-new/），呈现修复后规格并注明；
> - **C = 需用户决策**：默认不做，仅留档待确认；
> - **D = 观察不动**：记录在案，V1 照旧。

---

## 一、功能问题（重复 / 缺失入口 / 不合理流程）

### F-01 标题层级只有 1-3 级入口，H4-H6 无处可点【B1】

- 事实：高亮引擎支持 1-6 级（`MarkdownFormatter.applyATXHeaderFormatting` sizes=[28,24,20,18,17,16]，MarkdownFormatter.swift L292）；大纲解析也到 6 级（`MarkdownParser.parseHeadings` level 钳制 ≤6）；但格式化命令只有 `applyHeading1/2/3`（EditorView.swift L431-441），菜单（AppDelegate.swift L254-259）、快捷键（⇧⌘1/2/3）、工具栏（WindowController L131-139，仅 H1）全部止步 H3。对应逆向报告 F060。
- 影响：写长文（如本文档类结构）时 4-6 级只能手打 `####`，与"全键盘支持"的产品主张（README 核心特性 6）不一致。
- 处置：**B1**——V1 在 Format 菜单补 Heading 4/5/6（⇧⌘4/5/6），工具栏 Heading 按钮改为 H1-H6 下拉选择。这是给既有能力补入口，非新增功能。

### F-02 菜单查找导航项（⌘G/⇧⌘G/⌥⌘F）未联动自研面板【B2】

- 事实：三个菜单项绑定 `NSTextView.performFindPanelAction(_:)` 且未设置 actionTag（AppDelegate.swift L180-185），不会驱动 SearchReplaceController；自研查找能力只在 ⌘F 面板内可用。对应 F024（部分实现）。
- 影响：用户肌肉记忆的"⌘F 之后连按 ⌘G"在旧版实际走系统 find bar 路径（行为依赖系统，可能无响应或弹系统查找条），与面板状态割裂。
- 处置：**B2**——V1 呈现 ⌘G/⇧⌘G/⌥⌘F 与自研面板联动的规格（菜单项驱动面板的 Find Next/Previous/打开 Replace）。

### F-03 Replace All 不入撤销栈且破坏光标/选区【B3】

- 事实：`replaceAll` 直接 `textView.string = TextSearch.replaceAll(...)`（SearchReplaceController.swift L146-151），不注册 undo、光标与视口重置；违反 CLAUDE.md P0 规则 4「每个结构变更必须可撤销」。逆向报告 ⑨-4 已照实记录。
- 影响：误替换整文后无法 ⌘Z 回退，是全应用唯一违反撤销铁律的路径。
- 处置：**B3**——V1 呈现修复后规格：Replace All 以撤销组注册（可 ⌘Z 整体回退）、保持视口与光标、完成后给出"N 处已替换"结果反馈；界面注明旧版不可撤销的事实差异。

### F-04 GFM 表格在编辑器内无高亮【B4】

- 事实：`MarkdownParser` 已定义 tableRow/tableSeparator 块类型并用于导出（MarkdownParser.swift L88-96、L165-182），但 `MarkdownFormatter.applyLineFormatting` 无表格分支（MarkdownFormatter.swift L209-246）——表格行在编辑器内无专属着色。对应 F042 的"部分实现"。
- 影响：解析能力与视觉反馈不对等；表格行在长文中缺乏结构辨识度。
- 处置：**B4**——V1 原型为 tableRow/tableSeparator 行提供浅着色（分隔行弱化），并注明旧版缺失。

### F-05 静默失败点遍布写盘/导出/查找路径【B5】

- 事实与清单（全部已在逆向报告 ⑨ 登记）：
  1. 导出 HTML 写失败仅 DebugLog（AppDelegate.swift L397）；
  2. 自动保存失败仅 debugLog（Document.swift L201）；
  3. 图片写盘失败仅日志、不插入（ImageHandler.swift L126）；
  4. 正则非法 `try? NSRegularExpression` 静默返回原文（TextSearch.swift L17、L35）；
  5. 查找无命中无提示（SearchReplaceController.findNext 尾部无反馈）；
  6. 最近文档打开失败仅 DebugLog（AppDelegate.swift L337）；
  7. 打开非 UTF-8 文件回落空文档，无任何提示（Document.swift L167）。
- 影响：用户面对"导出了吗？""替换了几处？""文件为什么是空的？"无感知，排障成本高。
- 处置：**B5**——V1 为上述 7 点全部给出可见反馈（错误 alert / 面板内联状态 / toast），逐点注明旧行为。

### F-06 查找替换面板缺少结果计数与关闭快捷方式【B6】

- 事实：面板仅两输入框+复选框+三按钮（SearchReplaceController.swift L32-66），无命中计数、无 Esc 关闭的显式定义（窗口默认行为未验证【未知】）、无"已到文档末尾回绕"提示。
- 影响：批量修改场景（内容创作者画像）需要心里默数。
- 处置：**B6**——V1 面板增加「n/m 命中 · 已替换 n 处」状态行、回绕提示、Esc 关闭；为纯反馈增强，不新增查找能力。

### F-07 空文档阅读时间显示"1 min read"【B7】

- 事实：`readingTime = max(1, wordCount / 200)`（StatusBar.swift L115、L126），0 词显示 1 分钟。
- 影响：空文档/欢迎文本状态下统计失真，用户对"字符数 0 但阅读 1 分钟"产生困惑。
- 处置：**B7**——V1 呈现修复后规格：0 词显示 "0 min read"，>0 词维持最小 1 分钟规则；注明旧版怪癖。

### F-08 格式化命令三处重复实现（公共能力视角）【D1】

- 事实：`insertMarkdownAroundSelection`/`insertMarkdownAtLineStart` 在 EditorView.swift L487-515、Document.swift L311-351、MenuActions.swift L111-149 三处近乎复制；MenuActions 还用反射取 textView（MenuActions.swift L151-163）作为备用路径。
- 影响：行为漂移风险（已现雏形：EditorView 版调用 `scheduleMarkdownFormatting`，Document/MenuActions 版不调度）。
- 处置：**D1**（行为层面观察不动）+ 公共能力归位至 P7《module-split.md》编辑引擎模块统一实现；V1 原型不模拟三处差异。

### F-09 togglePreview 空壳方法【C1】

- 事实：`WindowController.togglePreview` 方法体仅日志 "Future: Add HTML preview toggle"（WindowController.swift L71-74），无 UI 入口。对应 F059（未实现）。
- 影响：死代码占位；且"预览"与产品定位"单栏源码可见"存在张力。
- 处置：**C1**——留档待用户决策：删除死代码 / 保留占位 / 立 v2 预览功能。V1 不实现预览（禁止私加功能）。

### F-10 帮助菜单无 Help book【C2】

- 事实：`showHelp` 无 .help bundle 绑定（AppDelegate.swift L296），点击行为【未知】。对应 F055。
- 处置：**C2**——留档：是否接入 docs/ 的 VitePress 站点或打包离线帮助，待用户决策。V1 菜单保留项并标注。

### F-11 代码块高亮回溯上限 100 行【C3】

- 事实：`expandRangeToIncludeCodeBlocks` 向前查找围栏时 `endLine + 100` 封顶（MarkdownFormatter.swift L175），超长代码块尾部编辑高亮可能不完整。
- 处置：**C3**——留档：放宽上限/全量围栏扫描的性能权衡，待用户决策；V1 不改变行为。

### F-12 空列表项智能键分支不可达（P4 走查新发现）【A2】

- 事实：`ListMarkerDetector.marker` 的三类模式（`^- `、`^\d+\.\s+`、`^-\s\[\s?\]\s+`）均要求 marker 后有内容；行 `"- "` 修剪后为 `"-"` 不匹配（ListMarkerDetector.swift L16-46）→ `handleReturnKey`/`handleBackspaceKey` 的空项分支（MarkdownTextView.swift L210-224、L300-318）永不执行。真实行为：Enter=普通换行且 marker 残留、Backspace=普通退格。`ListEditingTests.testEnterOnEmptyListItemDoesNotContinueList` 仅断言"不含续行 marker"，测试通过但未覆盖删除语义。
- 影响：F044/F046 在旧文档中登记为"已实现"，与真实行为不符（文档夸大）；写入 C6 重写策略输入。
- 处置：**A2**——直接勘误昨晚产物（reverse-analysis.md ⑤ F044/F046 行与 ⑨ 新增第 15 条、prd.md F044/F046 描述）；V1 原型按"文档意图的修复后规格"呈现（删 marker）并在 toast 注明差异。

---

## 二、页面问题（信息层级 / 操作路径 / 页面职责）

### P-01 工具栏 Heading 按钮固定为 H1，无层级选择【B1 关联】

- 事实：工具栏 `heading` 项 action 固定 `applyHeading1`，tooltip "Heading 1"（WindowController.swift L131-139）。
- 影响：H2/H3 高频操作只能走菜单/快捷键，工具栏职责（高频一键化）未覆盖。
- 处置：并入 **B1**（下拉选择 H1-H6）。

### P-02 大纲侧栏空态无引导【B8】

- 事实：无标题文档大纲为空列表，无任何文案（OutlineView.reloadOutline 直接 reloadData）。
- 影响：新用户不知道侧栏"何时会有内容"。
- 处置：**B8**——V1 空大纲显示引导文案「暂无标题 · 以 # 开始的行将出现在这里」；注明旧版为纯空列表。

### P-03 偏好窗口标题沿用 "Preferences"【D2】

- 事实：window.title = "Preferences"（PreferencesWindowController.swift L21）。macOS 13+ 系统 HIG 已改称 Settings（⌘, 入口名），旧项目最低支持 macOS 12。
- 处置：**D2**——跟随系统版本策略属实现细节，V1 原型按 macOS 13+ 惯例呈现 "Settings" 并注明，源码不动。

### P-04 状态栏位于窗口顶部（工具栏下方）而非底部【D3】

- 事实：`statusBarFrame` 在 `bounds.height - 28`（AppKit 坐标即视觉顶部，EditorView.swift L157-162）。
- 影响：与部分编辑器"底部状态栏"惯例不同，但自洽且专注模式可隐藏。
- 处置：**D3**——设计决策照旧，V1 保持顶部呈现。

### P-05 页面职责边界总体清晰，无越界页面

- 走查结论：14 页面职责单一（编辑/导航/统计/偏好/查找/系统面板），无职责重叠；PAGE002 菜单与 PAGE006 工具栏为同源命令的两个入口（设计使然，非重复页面）。

---

## 三、流程问题（跳转 / 路径 / 异常处理）

### L-01 查找流程的"面板外续搜"断链【B2 关联】

- 路径：⌘F 打开面板 → Find Next 选中 → 用户按 Esc/点编辑区继续写作 → 再按 ⌘G 期望续搜 → 旧版走系统动作，与面板无联动（同 F-02）。
- 处置：并入 **B2**。

### L-02 Replace All 后视口跳到文档头【B3 关联】

- 路径：长文中部执行 Replace All → `textView.string` 重置 → 光标/滚动位置丢失，视口回到初始位置（与 F-03 同根源）。
- 处置：并入 **B3**。

### L-03 打开损坏文件的"假空文档"风险【B5 关联】

- 路径：⌘O 选择非 UTF-8 文件 → 静默打开空文档（Document.swift L167）→ 用户若直接 ⌘S 会用空串覆盖原文件（自动保存开启时 3 秒后同样发生）。
- 影响：这是全部静默失败中后果最重的一条（潜在数据损失路径）。
- 处置：并入 **B5**（V1：解码失败 alert 提示且不进入自动保存计时；注明旧版行为）。

### L-04 关闭未保存窗口的保存询问依赖系统三选【D4】

- 事实：NSDocument 标准弹窗（保存/取消/不保存），行为系统托管。
- 处置：**D4**——照旧（符合 macOS 惯例）。

### L-05 专注模式下 ⌃⌘O 的状态组合未定义【D5】

- 事实：专注模式隐藏三件套（EditorView L365-381）；此时 ⌃⌘O 仍可展开侧栏（toggleSidebar 独立操作），形成"侧栏可见+状态栏/工具栏隐藏"的混合态；再次 ⌃⌘F 退出专注会把侧栏恢复 200pt（无论用户是否手动收起过）。
- 处置：**D5**——边界组合照旧，V1 不改变状态机（如实呈现）。

### L-06 新文档欢迎文本会被一并保存【D6】

- 事实：新建文档预填 `# Hello PaperMD\n\nStart typing...`（Document.swift L83），快速 ⌘S 后欢迎文本入文件。
- 处置：**D6**——产品决策照旧（场景 1"快速开写"依赖预填聚焦），V1 保持。

### L-07 大纲单击与双击同效跳转（冗余路径）【D7】

- 事实：`shouldSelectRow` 与 `doubleAction` 都触发 `onHeadingSelected`（OutlineView.swift L82-86、L137-141）。
- 处置：**D7**——冗余但无害，照旧。

---

## 四、公共能力识别（Component / Module / Service / Config）

> 这是 P7 模块拆分与 P5 组件库的输入。四层定义：Component=可复用 UI 单元；Module=可独立演进的引擎/领域逻辑；Service=跨模块支撑能力；Config=集中常量与策略。

### 4.1 Component（UI 组件，10 项）

| ID | 组件 | 来源文件 | 职责 | V1 关联 |
|----|------|----------|------|---------|
| CP-01 | 主窗口框架（红绿灯/标题/未编辑点/800×600） | Document.swift `openEditorWindow`、WindowController.swift | 文档容器 | — |
| CP-02 | 菜单栏（7 菜单程序化构建） | AppDelegate.swift `fixMenuStructure` L89-305 | 全量命令入口 | B1（H4-6 菜单项）、B2（查找项联动） |
| CP-03 | 工具栏（7 项 iconOnly） | WindowController.swift L58-195 | 高频格式化 | B1（Heading 下拉） |
| CP-04 | 大纲侧栏（NSTableView 缩进分级） | OutlineView.swift | 标题导航 | B8（空态文案） |
| CP-05 | Markdown 编辑区（styled source） | EditorView.swift、MarkdownTextView.swift | P0 输入载体 | — |
| CP-06 | 状态栏（词/字符/阅读时间） | StatusBar.swift | 写作统计 | B7（0 词修复） |
| CP-07 | 查找替换面板（420×160） | SearchReplaceController.swift | 检索替换 | B2/B3/B6（联动/撤销/计数） |
| CP-08 | 偏好窗格（450×300 三分区） | PreferencesWindowController.swift | 全局偏好 | D2（标题措辞） |
| CP-09 | 系统面板适配（Open/Save/Export/Print/About） | AppDelegate、Document、ExportHelper | 文件与交付 | B5（失败反馈） |
| CP-10 | 专注模式视图态（三隐藏+0.25s 动画） | EditorView L358-381、WindowController L267-271 | 免打扰 | — |

### 4.2 Module（领域模块，7 项）

| ID | 模块 | 来源文件 | 职责 | 备注 |
|----|------|----------|------|------|
| MD-01 | 编辑引擎（TextKit 1 管线+IME 保护+光标保持+格式化调度） | EditorView.swift L50-81、L217-323；MarkdownTextView.swift | 输入体验核心 | F-08 三处重复待归位 |
| MD-02 | 语法高亮引擎（行级增量+代码块扩展） | MarkdownFormatter.swift | 属性叠加渲染 | B4 补表格分支 |
| MD-03 | Markdown 解析核心（14 块类型+标题+导出） | MarkdownParser.swift | 单一事实解析 | — |
| MD-04 | 智能列表编辑（续行/终止/缩进/删空项） | ListMarkerDetector.swift、MarkdownTextView L196-322 | 键盘智能行为 | — |
| MD-05 | 查找替换引擎（字面量/正则） | TextSearch.swift | 检索算法 | B3 撤销集成在 MD-01 |
| MD-06 | 图片资产管线（落盘/插入/迁移/撤销组） | ImageHandler.swift | 资源管理 | — |
| MD-07 | 导出管线（HTML 生成+WKWebView 打印） | ExportHelper.swift、MarkdownTheme.css | 交付 | — |

### 4.3 Service（支撑服务，6 项）

| ID | 服务 | 来源文件 | 职责 |
|----|------|----------|------|
| SV-01 | 偏好存储（UserDefaults 3 键） | PreferencesWindowController.swift L235-307 | 读写+广播+启动应用 |
| SV-02 | 自动保存调度（3 秒一次性 Timer） | Document.swift L188-206 | 静默落盘 |
| SV-03 | 撤销系统（NSUndoManager 窗口级+文件级撤销组） | MarkdownTextView、ImageHandler L203-234 | 全操作可逆 |
| SV-04 | 文档持久化（UTF-8 读写/writeSafely） | Document.swift L129-177 | 文件即文档 |
| SV-05 | 统计服务（词/字符/阅读时间） | StatusBar.swift L104-128 | 状态栏数据 |
| SV-06 | 日志服务（DebugLog） | Core/DebugLog.swift | DEBUG 输出 |

### 4.4 Config（配置与常量，6 项）

| ID | 配置 | 来源文件 | 内容 |
|----|------|----------|------|
| CF-01 | 主题色板（编辑器+导出 CSS 双端） | MarkdownTheme.swift | 11 语义色×明暗 |
| CF-02 | 偏好默认值 | PreferencesWindowController L271-280 | 16/system/true |
| CF-03 | 窗口尺寸常量 | Document L63、PreferencesWindowController L16、SearchReplaceController L19 | 800×600 / 450×300 / 420×160 |
| CF-04 | 工具栏项序列 | WindowController L182-194 | 9 identifier 固定序 |
| CF-05 | 菜单结构与快捷键表 | AppDelegate L89-305 | 约 40 项 |
| CF-06 | 欢迎文本/图片命名规则/资产目录约定 | Document L83、ImageHandler L12/L76-85 | 常量与命名策略 |

---

## 五、分级处置汇总

| 级别 | 编号 | 数量 |
|------|------|------|
| A（文档勘误，已改） | A1（P6 归位引发：page-spec.md 与 html-acceptance-report.md 的原型路径引用更新为 prototype/v0-old/）；A2（F044/F046 空项分支不可达——勘误 reverse-analysis.md ⑤/⑨ 与 prd.md §5，见 F-12） | **2** |
| B（V1 落地） | B1 H4-H6 入口（F060/P-01）、B2 查找导航联动（F024/L-01）、B3 Replace All 可撤销+视口保持（F022/L-02）、B4 表格高亮（F042）、B5 七处静默失败反馈（L-03 等）、B6 查找面板计数/Esc/回绕提示、B7 阅读时间 0 词修复、B8 大纲空态引导 | **8** |
| C（待用户决策） | C1 togglePreview 死代码处置、C2 帮助菜单接入方式、C3 代码块回溯上限、C4 ⌥⌘C 双义改键（见 §六）、C5 TextKit 1→2 迁移、C6 14 项代码级隐患重写策略、C7 Main.storyboard 移除 | **7** |
| D（观察不动） | D1 格式化三处重复实现（归 P7）、D2 偏好标题措辞、D3 状态栏顶部、D4 关闭询问系统三选、D5 专注×侧栏混合态、D6 欢迎文本入文件、D7 大纲单击双击冗余 | **7** |

> 注：C4-C7 四项在功能/页面/流程走查中未单列条目，因其属"重写期工程决策"而非交互缺陷，源自逆向报告 ⑨ 已登记的 14 项代码级隐患与遗留资产，统一收口到 C 类。

### ⌥⌘C 双义冲突（C4 详述）

- 事实：Edit → Transformations → Capitalize 与 Format → Code Block 同为 ⌥⌘C（AppDelegate.swift L209-212 vs L267-269）。AppKit 按菜单启用态与顺序匹配 keyEquivalent，实际触发不可靠（通常 Edit 菜单项优先），导致 Format → Code Block 的快捷键可能永远无法命中。
- 留档选项（默认全部不动，待用户确认）：a) Code Block 迁移至新键（如 ⇧⌘K）；b) Capitalize 移除快捷键；c) 维持现状并接受 Code Block 依赖菜单/工具栏。
- V1 原型处理：菜单按旧值呈现，冲突项加 ⚠ 标注说明（不复制"按键不触发"的 bug 行为，标注即可）。

---

## 六、A 类勘误执行记录

| # | 文件 | 修改内容 | 原因 |
|---|------|----------|------|
| A1-1 | docs/02_product/PAGE_SPEC.md L5 | 「本文档约束 HTML 原型（prototype/app-prototype.html）」→「本文档约束 HTML 原型（prototype/v0-old/app-prototype.html，V1 新原型见 prototype/v1-new/app-prototype.html）」 | P6 将旧原型归位至 v0-old |
| A1-2 | docs/09_test/HTML_V0_ACCEPTANCE.md L4 | 「验收对象：prototype/app-prototype.html」→「验收对象：prototype/v0-old/app-prototype.html（v0 旧版原型，已归位）」 | 同上 |
| A2-1 | docs/01_reverse/REVERSE_ANALYSIS.md ⑤ F044 行 | 状态改注「已实现（分支存在；实际未触发）」+ 不可达原因说明 | P4 走查新发现（见本报告 F-12） |
| A2-2 | docs/01_reverse/REVERSE_ANALYSIS.md ⑤ F046 行 | 同上 | 同上 |
| A2-3 | docs/01_reverse/REVERSE_ANALYSIS.md ⑨ 部分实现 | 新增第 15 条「空列表项智能键分支不可达」 | 同上 |
| A2-4 | docs/02_product/PRD.md §5 F044/F046 行 | 描述补【A2 勘误】注记 | 同上 |

> 其余昨晚产物（prd.md 其它行 / html-coverage-checklist.md）经与源码逐条复核：行号引用、快捷键值、默认值、功能状态四类事实一致，无其它 A 类勘误。

---

## 七、移交清单

- B1-B8 → P5 Design System（组件规格含 V1 变体）、P6 V1 原型（落地呈现）、docs/09_test/V1_ACCEPTANCE.md（逐项核验）。
- CP/MD/SV/CF 四层公共能力 → P7 docs/04_architecture/MODULE_ARCH.md 归位映射。
- C1-C7 → 保持未决策状态，在 V1 原型评审面板与 v1-acceptance 留档，等待用户逐项确认。
