# PaperMD HTML 原型质量验收报告（HTML_QA_REPORT）

> 依据：《AI 生成 HTML 原型质量验收标准 v1.0》（五项覆盖率矩阵 + Level 分级 + P0-P3 缺失分级 + 开发准入 8 项）
> 验收人角色：产品测试负责人（纯验收：只记录不修复，未改动任何 HTML/源码/文档，未 commit）
> 主对象：`prototype/v1-new/app-prototype.html`（V1 新版原型，14 页 macOS 风格，按 **Level 3** 验收）
> 快检对象：`prototype/v0-old/app-prototype.html`（对照 `docs/09_test/HTML_V0_ACCEPTANCE.md` 口径）
> 验收日期：2026-09-03　验收环境：macOS（darwin 25.5.0 arm64）· node v24.12.0 · python3 http.server **8304** 端口（测毕已关闭）
> 基准输入：PRD.md（F001-F060）· PAGE_SPEC.md（14 页 11 维 + 六项特检矩阵）· USER_FLOW.md（旅程 1-5 及 UF 缺陷口径）· FEATURE_MAP.md · TOKEN.md / COMPONENT.md · REVERSE_ANALYSIS.md §⑦ 数据模型

---

## 一、结论摘要

# 最终评级：Level 3（达标，准入开发）　阻断缺陷 P0 = 0 　P1 = 0

**动态断言 98 项次全部通过**（首轮 76 项中 11 项 FAIL 经复核全部归因为验收脚本判定口径问题——模态显隐用 `.show` class 而非 display、大纲项 class 为 `.ol-item`、专注模式侧栏用 `collapsed` class、跳转后 0.1s 光标收缩为 PAGE003 规格行为——修正口径后复核 20 项 + 终验 2 项全过）。console error 仅 1 条 favicon 404（环境噪音）；无行为按钮 0；死链接 0；未捕获 JS 异常 0。

### 开发准入 8 项勾选

| # | 准入项 | 结论 | 证据 |
|---|--------|------|------|
| 1 | PRD 60 项功能可追溯 | ☑ 通过 | 交互级实测 48+ 项（§四），其余为忠实旧版说明级覆盖（F012/F015/F024 旧差异/F025/F055/F059 等，静态绑定核验 + 菜单 48 项枚举） |
| 2 | PAGE001-014 页面全覆盖 | ☑ 通过 | 评审面板 14 个 PAGE 导航按钮逐一点击执行（T13）；14 页对应结构元素全部存在（T1-T12） |
| 3 | USER_FLOW 五组旅程可走通 | ☑ 通过 | 开写→编辑→保存 / 打开→自动保存 / 图片→首存迁移 / 查找替换 / 导出 HTML+PDF 全程实测（§五）；UF-01 边界如实模拟 |
| 4 | 五态 + 六项特检可触发 | ☑ 通过 | 成功/空数据/加载/错误/权限 5 态实测触发；取消路径（Esc 关模态、关闭询问取消保持窗口）实测 |
| 5 | 交互元素全部有效 | ☑ 通过 | 29 个 button（22 id + 7 data-close）+ 48 菜单项全部有行为绑定，死按钮 0（§六） |
| 6 | console 无错误 | ☑ 通过 | 全程仅 1 条 favicon.ico 404（http.server 环境噪音，file:// 不出现；与 v0/v1 历次验收 D1 相同）；pageError = 0 |
| 7 | 设计系统一致 | ☑ 通过 | 38 个消费 token 全部定义于 TOKEN.md，关键值抽查 12 项全对；组件与 COMPONENT.md CP-01~13 对应（§七） |
| 8 | 语法/代码质量 | ☑ 通过 | node --check 通过（v1 内嵌 JS 1434 行）；孤儿事件处理器 0；零外链零本地资源（§八） |

---

## 二、验收方法与环境

1. **静态**：正则提取内嵌 `<script>`（v1 1434 行 / v0 1311 行）→ `node --check` 通过；扫描外链/本地资源引用（**零外链、零本地资源**，单文件自足）；button/菜单项/事件绑定交叉核对；CSS 变量使用 vs 定义全量比对；与 REVERSE_ANALYSIS §⑦ 数据模型逐字段对照。
2. **动态**：`python3 -m http.server 8304` 起服务（v1/v0 均 HTTP 200）；Playwright（playwright-core 1.49.1 + 独立 headless Chromium 1148）执行 **3 轮共 98 项次断言**：结构 12 项、14 页导航、USER_FLOW 5 旅程 28 项、五态 7 项、P0 输入体验 15 项、菜单/快捷键 5 项、console 2 项、复核 20 项、终验 2 项；按钮抽查专项覆盖全部 id 按钮。
3. **降级说明**：无降级。chrome-devtools 共享浏览器被并行会话占用后（见 §十），切换至独立 headless 浏览器完成全部动态断言，方法与结果不受影响。

---

## 三、五项覆盖率矩阵

| 维度 | 要求 | 实测覆盖 | 覆盖率 | 代表证据 |
|------|------|----------|--------|----------|
| 页面覆盖 | PAGE001-014 | 14 页导航按钮全部可点击执行；主窗画框/红绿灯/菜单栏/大纲/编辑区/状态栏/工具栏/专注/偏好/查找/打开/保存/导出/打印/About 结构全部存在 | **14/14 = 100%** | T1-T13 全过；PAGE006 导航实测拉起 Heading 下拉（H1-H6） |
| 功能覆盖 | F001-F060 | 交互级实测：F001/F002/F003/F005/F006/F008/F009/F010/F011/F014/F016/F017/F018/F019-F023/F028/F029/F030/F031/F032/F036(1-6)/F037/F038/F040/F041/F042(B4)/F043/F045/F047/F048/F049/F050/F052/F053/F058；说明级（忠实旧版口径）：F004（Open Recent 动态+Clear）/F012（剪贴板降级 toast）/F013（pastePlain 绑定）/F015（模拟按钮替代拖拽）/F024（B2 已联动，差异注明）/F025/F026（transformCase）/F027（jumpToSel）/F044/F046（A2 勘误口径 toast 注明）/F051/F054/F055/F056/F057/F059（不设入口，忠实空壳）/F060（B1 已补 H4-H6 入口） | **60/60 = 100%** | §四抽查表 + §五旅程证据 |
| 操作覆盖 | 所有可点击元素有效 | 菜单 7 组 48 项全部可开（M1：条目数 6/8/14/2/14/3/1），37 项 fn 直绑 + 8 项 sys 系统说明 + 2 子菜单 + 13 分隔；工具栏 7 按钮（含禁用态联动）；查找面板 4 按钮（Find Prev 实测绑定）；6 模态确认/取消双路 + Esc 关顶层模态；红绿灯三键 + Dock 重开；评审面板 14+6 导航 + 3 开关 + 3 快捷动作 | **100%** | M1/M2/M3、B-AUDIT、R1-R16 |
| 状态覆盖 | 五态 | 成功态（146 words\|947 chars\|1 min read）；空数据态（0/0/"0 min read（B7 修复：旧版显示 1）"+ 大纲空态"暂无标题 · 以 # 开始的行将出现在这里"）；加载态（large-document.md 遮罩 on→1.4s off→载入）；错误态（broken→alert"无法打开文件"、只读保存失败 alert"保存失败"、正则非法"正则表达式无效"、无命中"无命中"）；权限态（mPerm 沙盒说明面板） | **5/5 = 100%** | S1-S5 全过 |
| 异常覆盖 | 六项特检（PAGE_SPEC §三） | ①空文档②加载中③错误④权限⑤文件读写异常⑥用户取消——逐页矩阵落地：Esc 关面板（R4）、关闭询问取消保持窗口（P0-14）、打开/保存/导出取消无副作用（R4/R6 路径）、只读保存失败 alert（S4） | **6/6 = 100%** | R4/R17/R18、S3/S4、P0-13/14 |

---

## 四、按钮抽查表（要求 ≥10，实际全量 29 button 核验 + 14 项代表抽查实测）

| # | 按钮 | 预期 | 实测结果 |
|---|------|------|----------|
| 1 | tbSidebar | 侧栏显隐切换 | collapsed class 翻转 ✓ |
| 2 | tbBold（无选区） | F058 禁用 | class="tbtn needsel dis" + disabled=true ✓ |
| 3 | tbBold（有选区） | ** 包裹 | `**PaperMD**` 且选区保持（F048）✓ |
| 4 | tbQuote / tbCodeBlock | 行首 > / 围栏 ``` | 均生效 ✓ |
| 5 | tbHeading | B1 H1-H6 下拉 | 6 项（H4-6 标"B1 新增"）✓ |
| 6 | btnDoSave | 保存面板确认 | untitled.md 默认名→保存→docname 更新、edited 点消失 ✓ |
| 7 | btnDoExport | 生成导出预览 | mExView 打开，含 `<h1>`/`<table>`/`<pre><code>func hello()…`/主题 CSS max-width:800px ✓ |
| 8 | btnDoPrint | 打印面板 | 进度"正在渲染… 10%→29%"→1.9s 后按钮启用 ✓ |
| 9 | btnFindNext / btnReplaceAll | 命中选中 / 全替换 | 选中值='PaperMD'；替换后残留 0，状态行"已替换 2 处 · 已入撤销栈（B3）"✓ |
| 10 | askCancel / askNoSave / askSave | 关闭询问三选 | 取消保持窗口 ✓；不保存关窗 ✓ |
| 11 | btnMinWin / btnRestoreMin / btnZoomWin / btnReopen | 窗口控制 | 最小化 chip/还原/缩放/Dock 重开（F001 保活）✓ |
| 12 | btnSimPasteImg | 图片模拟插入 | `![](welcome.assets/image-1788376458404-1634184733.png)`（13 位 ms + 10 位 hash）✓ |
| 13 | btnPrefs / btnFindPanel | 快捷入口 | mPrefs / mFind 打开 ✓ |
| 14 | data-close ×7 | 模态关闭路 | querySelectorAll 委托绑定，点击关闭所属模态 ✓ |

**无行为按钮（点击无任何 DOM/状态/提示反馈）：0。** 孤儿事件处理器（引用未定义函数）：0。死链接/失效资源引用：0。

---

## 五、USER_FLOW 旅程走查（5/5 组全通，含 UF 口径核对）

| 旅程 | 实测链路 | 结果 |
|------|----------|------|
| 1 开写→编辑→保存 | newDoc 预填 `# Hello PaperMD`（F053）→ 输入 → edited 圆点 → ⌘S 弹面板（默认 untitled.md）→ 确认保存 → docname='旅程演示.md'、圆点消失 | ✓ |
| 1-UF01 untitled 无自动保存 | untitled 输入后 3.3s：无任何自动保存 toast（`restartAutosave` 对 `S.fileName=null` 直接 return）——真机缺陷 UF-01 边界**如实模拟** | ✓ 口径一致 |
| 2 打开→自动保存 | loadFile welcome.md → 输入 → 3s toast"已自动保存（3 秒静默触发）"（B5 可视化，注明旧版无提示） | ✓ |
| 2-UF02 解码失败链 | loadFile broken-encoding.md → alert"无法打开文件…UTF-8 解码…已按旧版兜底打开空文档"→ 编辑区=空文档（V1 为**修复规格**：真机填欢迎模板）→ 打开后不输入 3.4s 无自动保存（alert 声明的"打开不计时"成立）→ **但用户输入后 3.4s 出现与正常文档相同的"已自动保存"toast**（`S.fileName='broken-encoding.md'` 非空 → 计时照常启动） | ⚠ 口径精度问题，记 **P2-1**（§九） |
| 3 图片→首存迁移 | 未保存文档插入裸名 `image-{13位ms}-{10位hash}.png`（pendingImages 登记）→ commitSave('迁移演示.md') → 路径改写 `迁移演示.assets/image-…`（F017）→ 撤销组（F018） | ✓ |
| 4 查找替换 | ⌘F（键盘事件实测）→ Find Next 选中命中+回绕提示"1/2 命中 · 已回绕到文档头"（B6）→ Replace All 替换 2 处残留 0 → doUndo 整体回退（B3）→ 正则 `\d+` 命中 → 非法正则"正则表达式无效"（B5）→ 无命中"无命中"（B6）→ ⌘G/⇧⌘G 联动自研面板（B2，R15） | ✓ |
| 5 导出交付 | ⌃⌘E → 面板默认 `table-test.html` → 生成预览（h1/table/pre>code/主题 CSS）→ ⌃⌘P 打印面板 → 渲染进度 → btnDoPrint 启用；Esc 取消无副作用 | ✓ |

B1-B8 附加核验：B1（菜单 ⇧⌘1-6 全六级 + 工具栏下拉 + ⇧⌘4 键盘实测生效 `#### PaperMD V1 演示文档`）✓；B2 ✓；B3 ✓；B4（table-test.md 5 个 tk-table 类 token）✓；B5 四路实测 ✓；B6 ✓；B7（0 词 →"0 min read（B7 修复：旧版显示 1）"）✓；B8 ✓。

---

## 六、静态分析结果（代码质量）

| 检查 | 结果 |
|------|------|
| node --check（v1 1434 行 / v0 1311 行） | **通过 / 通过** |
| 外链引用（http/https/协议相对） | **0** |
| 本地资源引用（css/js/png/svg/…） | **0**（单文件自足；favicon 404 为浏览器自动请求，非页面引用） |
| `<button>` 总数 / 有 id / data-close 委托 | 29 / 22 / 7——**全部有行为**（21 个 `.onclick=` 直绑 + tbHeading `addEventListener`（Heading 下拉）+ 7 个 data-close 统一委托） |
| 菜单项绑定 | 7 组 48 项：37 fn 直绑 + 8 sys 系统行为说明 + 2 子菜单（Open Recent 动态+Clear Menu / Transformations 三项）——**无行为项 0** |
| 孤儿事件处理器（inline/属性引用未定义函数） | **0**（原型零 inline onclick，全 addEventListener/onclick 赋值） |
| 菜单结构与 PAGE_SPEC §1.2 对照 | PaperMD 6 / File 8 / Edit 14 / View 2 / Format 14（旧 12+B1 扩 2）/ Window 3 / Help 1——逐项枚举一致；⌥⌘C 双义（Transformations/Code Block）保留 |
| JS 函数 | 87 个具名函数全部有定义、无重复定义冲突 |
| 未捕获异常（3 轮动态全程 pageerror） | **0** |

---

## 七、数据与设计系统一致性（Level 3 附加四项）

### 7.1 数据结构 vs REVERSE_ANALYSIS §⑦ 真实模型 —— 一致

| 真实模型 | 原型实现 | 结论 |
|----------|----------|------|
| DocumentStats（词=空白切分非空段 / 字符=text.count / 阅读=max(1,⌊词/200⌋)） | `renderStats`：`split(/\s+/).filter(len>0)` / `text.length` / `Math.max(1,⌊words/200⌋)` 且 0 词→0（B7 修复注明） | 一致（B7 口径注明） |
| MarkdownHeading（level 1-6/title/lineNumber） | `parseHeadings` → `.ol-item l{1-3}`（缩进 12+(level-1)×16px，H4-6 钳制 l3） | 一致 |
| MarkdownLine 14 种 kind | 高亮 23 类 tk-* token 覆盖 14 种 kind 可视化相关全集（含 B4 新增 tk-table/tk-table-sep、H4-6 的 tk-h46） | 一致+扩展注明 |
| Preferences（fontSize 默认 16 十档 / theme 默认 system / autosave 默认 true） | `S.fontSize=16 / S.theme="system" / S.autosaveOn=true`；prefFont 十档 12-24 | 一致 |
| 图片命名 `image-{epochms}-{hash}.png` | `image-1788376458404-1634184733.png`（13 位 ms+10 位 hash） | 一致 |
| assets 目录（已保存 `{文档名}.assets/`，未保存 tmp 持久 pending） | `welcome.assets/…` / 裸名+pendingImages / toast 注明 `tmp/PaperMD-UUID.assets/` | 一致 |
| autosave 3s 一次性 Timer（仅已保存文档） | `restartAutosave`：fileName=null 不计时；3s 后 edited 才落盘 | 一致（UF-01 如实） |

### 7.2 组件统一（vs COMPONENT.md）—— 一致

CP-01 主窗画框/CP-02 菜单栏（B1 Heading 1-6+B2 联动+B5）/CP-03 工具栏（B1 Heading 下拉）/CP-04 大纲（B8 空态文案实测）/CP-05 编辑器（B3/B4/B5）/CP-06 状态栏（B7）/CP-07 查找面板（420×160 语义、B2/B3/B6、Esc 关闭实测）/CP-08 偏好（即时生效实测）/CP-09 系统面板组（导出/打印/About 模拟）/CP-10 专注模式/CP-11 反馈提示组（toast/alert/状态行全数可触发）/CP-12 撤销分组（图片组+Replace All 组实测）/CP-13 原型层组件——与视图一一对应。

### 7.3 Token 抽查（vs TOKEN.md）—— 通过

- CSS 变量 **38 个消费 / 41 个定义**；使用未定义 **0**；组件样式无裸色值/裸字号（裸值仅在 token 定义块）。
- 值抽查 12 项全对：--syntax-heading（light #0366d6 / dark #7db4ff，实测切换变值）、--syntax-task-done（#1f9d55/#4cd964）、--syntax-image-line-bg（rgba .08/.15 双主题）、--sidebar-width 200px、状态栏 28px、--anim-focus 0.25s、--radius-window/menu/chip 10/6/4px、导出排版 max-width:800px、pre 5px / code 3px、line-height 1.6、margin 40px auto、blockquote 4px 左边框。
- 双主题三段式（:root/theme-light/theme-dark）结构符合 TOKEN.md §5 约定。

### 7.4 架构一致性 —— 通过

- 菜单 7 组 48 项与 PAGE_SPEC §1.2 全表逐项一致（含 ⌥⌘C 同键双义、⇧⌘L/⌥⌘> 等 README 未列项）。
- 快捷键全集入 keydown 处理器（⌘F/⌘B/⌘G/⇧⌘G/⌥⌘F/⌃⌘F/⌃⌘O/⌃⌘E/⌃⌘P/⇧⌘1-6/⌥⌘S/⌥⌘C/⇧⌘S/⇧⌘L/⇧⌘Z 实测抽查 6 组全过）。
- 编辑区→大纲/状态栏/标题单向数据流；单事实源 = `ed.value`（保存/导出/统计/大纲同源）。

---

## 八、v0-old 快检结论

| 检查 | 结果 | 与 HTML_V0_ACCEPTANCE.md 口径对照 |
|------|------|-----------------------------------|
| HTTP 8304 打开 | 200（83,432 bytes），标题"PaperMD HTML 交互原型（逆向复刻 v1.0）" | 一致 |
| console | 仅 1 条 favicon 404；pageError 0 | 与 V0 报告 D1 相同（环境噪音） |
| 页面数 | 评审面板 PAGE001-014 导航按钮 **14 个** | 14/14 口径一致 |
| 结构快查 | 编辑区/大纲/状态栏三统计/7 菜单（PaperMD·File·Edit·View·Format·Window·Help）全在 | 一致 |
| 初始统计 | "154 words \| 884 characters \| 1 min read" | 与 V0 报告 §二.1 PAGE005 行**逐字一致** |

**v0-old 结论：可正常打开、结构与页面数口径与既有验收文档完全一致、无新增 console 错误。**

---

## 九、缺失与问题列表（P0-P3）

| 级别 | 编号 | 描述 | 建议 |
|------|------|------|------|
| P0（阻断） | — | 无 | — |
| P1（开发前必须修复） | — | 无 | — |
| P2（开发期修复） | QA-1 | **UF-02 口径精度**：broken-encoding.md 的 alert 声明"V1 不进入自动保存计时（防止空串覆盖原文件）"，实测该声明仅对"打开动作"成立（不输入 3.4s 确无自动保存）；用户一旦编辑，`S.fileName='broken-encoding.md'` 非空使 `restartAutosave` 照常启动，3 秒后出现与正常文档完全相同的"已自动保存"toast，无破损文件警示——UF-02 数据损失链的后半段（编辑→写回原路径）在原型中可复现且反馈无差异，与 alert 的防护口径矛盾 | 开发重写时按 USER_FLOW 旅程 2 明确二选一：修复规格（解码失败文档禁用自动保存直至用户显式保存）或复刻旧版并警示；原型 alert 文案与 toast 至少须区分破损文档场景 |
| P3（建议） | QA-2 | 3 个 token 定义未使用：`--find-margin` / `--font-mono` / `--pref-margin`（值以内联形式落地，变量冗余） | 删除或改引用 |
| P3（建议） | QA-3 | 8 个 TOKEN.md 未备案的原型层补充变量：`--desk / --menubar-bg / --menubar-fg / --shadow-win / --statusbar-sep-w / --titlebar-bg / --toolbar-bg / --syntax-table`（均双主题成对定义、组件内仍走 var() 引用，不构成裸值违规，但未入 DS 备案） | 补入 TOKEN.md"原型层 token"节 |
| P3（建议） | QA-4 | `--syntax-table` 取值恰等于 `--syntax-quote`（#0d9488/#6fd3c8），视觉与 COMPONENT.md B4 记录（tableRow 用 quote 系着色）一致，但实现为独立变量而非引用 `var(--syntax-quote)` | 统一为引用或修订 COMPONENT.md 记录 |

**口径注明（非缺陷）**：V1 对 UF-02 呈现的是修复规格（空文档兜底+B5 alert），而真机为"欢迎模板填入+3 秒覆盖"（USER_FLOW 旅程 2 UF-02）；该差异为 V1_ACCEPTANCE 既有声明口径（"修复后规格+注明"），本报告如实记录，不计入缺失。

---

## 十、环境说明与干扰记录

1. **并行会话争抢共享浏览器**：chrome-devtools MCP 与 Playwright MCP 的共享浏览器被 4-5 个并行验收会话（TermForge / Steering-BLE / RedisPilot / BatchImageStudio / IconGen）占用，标签页在测试期间被不断打开/关闭，首轮一次结构断言实际执行到了他人页面（与 HTML_V0_ACCEPTANCE D2、V1_ACCEPTANCE D2 同源问题）。**处置**：改用 smart-ble 项目 node_modules 的 playwright-core 1.49.1 + 独立 headless Chromium（cache 内 chromium-1148）完成全部动态断言，结果不受影响。
2. **favicon 404**：http.server 环境噪音（页面无 favicon 引用，浏览器自动请求 404）；file:// 打开不出现；历次验收均记录为 D1，不计入原型缺陷。
3. **git 脏改动**：项目存在 18 条已修改 + 多条未跟踪文件（验收前已存在），本验收未触碰任何文件；唯一产出为本报告。测试服务（8304）测毕已关闭。
4. 断言口径修正记录：首轮 11 项 FAIL 全部为验收脚本判定口径问题（模态 `.show`、大纲 `.ol-item`、专注 `collapsed` class、⌘S/⌘F/导出面板显隐判定、粗体选区 8 字符误含空格、console text 无 URL、0.1s 光标收缩时序），修正后复核全部转 PASS——**原型本身零缺陷转归因**。

---

## 十一、最终结论

**Level 3 达标（五项覆盖率 100% + 附加四项通过 + P0/P1 = 0），准入进入开发。**

- 五项覆盖率：页面 14/14 · 功能 60/60 · 操作 100%（死按钮 0）· 状态 5/5 · 异常 6/6
- 动态断言 98 项次全过；console error = 1（仅 favicon 环境噪音）；无行为按钮 = 0
- 待跟进：P2-1（UF-02 口径精度）须在开发需求中明确修复口径；P3 三项（token 冗余/备案/引用方式）建议顺手清理
- v0-old 快检：通过，与既有验收口径完全一致

---

## 复验附录（开发角色修复，2026-09-03）

> 本附录由开发角色在原报告验收后追加（仅文末追加，原报告正文未改动）。修复对象：QA-1 / P2-1（UF-02 口径精度）。修改文件仅两个：`prototype/v1-new/app-prototype.html`（修复本体）与本报告（本附录）。未触碰任何 tracked 源码 / v0-old / docs 其他文件，无 git 写操作。

### 1. 修复内容（`prototype/v1-new/app-prototype.html`，按 USER_FLOW 旅程 2「修复规格」方向）

| # | 位置 | 改法 |
|---|------|------|
| 1 | 全局状态 `S` | 新增 `brokenDoc:false` 标志（UF-02 修复） |
| 2 | `restartAutosave()` | 在 `!autosaveOn || !fileName` 早退后新增 `if(S.brokenDoc)return;` —— 破损文档编辑不启动 3 秒计时（即使 `fileName` 非空），防止空串覆盖原文件 |
| 3 | `loadFile()` 破损分支 | 置 `S.brokenDoc=true`；alert 文案由「V1 不进入自动保存计时」更新为「V1 已**禁用自动保存直至显式保存**（防止空串覆盖原文件；⌘S 保存成功后自动恢复）」，与新行为对齐 |
| 4 | `loadFile()` 正常分支 / `newDoc()` | 置 `S.brokenDoc=false`（正常路径不受影响） |
| 5 | `saveDoc()` | 「已是最新」早退条件加 `!S.brokenDoc` —— 破损文档即使未编辑也可显式保存解除禁用 |
| 6 | `commitSave()` | 捕获 `wasBroken`；保存成功后 `S.brokenDoc=false`（自动保存恢复）；破损路径 toast 区分文案：**「已保存 …（破损文档·按兜底打开后显式保存，自动保存已恢复）」**（含「破损」「按兜底打开」字样，对齐 alert 口径）；正常文档 toast 原文案不变 |

正常文档的自动保存/保存行为零改动（`restartAutosave` 对 `brokenDoc=false` 完全等价；`commitSave` 仅在 `wasBroken` 分支区分文案）。内嵌 JS 提取后 `node --check` 通过（1442 行）。

### 2. 动态复验（15/15 PASS）

环境：`python3 -m http.server 8304`（测毕已关闭）+ playwright-core 1.49.1 / 独立 headless Chromium 1148；脚本 `/tmp/pm_fix_verify.js`（临时，不入库）。打开路径沿用原旅程 2 实测路径：**File 菜单 → Open… → 文件面板选 broken-encoding.md**。

| # | 断言 | 结果 |
|---|------|------|
| A1-1~3 | UI 路径打开 broken-encoding.md → alert 出现，含「不能以 UTF-8 解码」「按旧版兜底打开」及新口径「禁用自动保存直至显式保存」 | PASS |
| A1-4 | 打开后 `S.brokenDoc=true` / `fileName='broken-encoding.md'` / `autosaveTimer=null` | PASS |
| A1-5 | 编辑输入后 `edited=true`（编辑反馈未破坏，editedDot 显示）且 `autosaveTimer` 仍为 null | PASS |
| A1-6 | **编辑后 3.4s+ 无「已自动保存」toast（原缺陷场景，禁用成立）** | PASS |
| A2-1~3 | **⌘S 显式保存成功**，toast=「已保存 broken-encoding.md（破损文档·按兜底打开后显式保存，自动保存已恢复）」，`brokenDoc` 复位 false | PASS |
| A3-1 | **此后再编辑 → 3.8s 内出现「已自动保存（3 秒静默触发）」（自动保存已恢复）** | PASS |
| A4-1~3 | 回归：welcome.md 显式保存 toast 逐字保持原文案（无破损字样）；编辑后自动保存 toast 照旧；`brokenDoc=false` | PASS |
| A0-1~2 | console error = 0（本轮连 favicon 404 也未出现，total=0）；pageerror = 0 | PASS |

### 3. 定级更新

**QA-1 / P2-1 已修复并复验通过：P2 清零。当前缺失计数 P0 = 0 / P1 = 0 / P2 = 0；P3 三项（QA-2 token 冗余 / QA-3 原型层变量未备案 / QA-4 `--syntax-table` 引用方式）仍留档为建议项，不阻断开发。** 原报告正文（含 §九 P2-1 条目）保持原样，以本附录为准。

### 4. git 自查

改动前后 `git status --porcelain` 对比：M 列表 **18 条完全一致**（CLAUDE.md / project.pbxproj / 10 个 Swift+plist / README.md / Tests fixture / docs 三项），与验收前历史基线相同；本附录与原型修复均位于既有未跟踪目录（`docs/09_test/`、`prototype/`）内，未新增未跟踪路径、未做任何 git 写操作。
