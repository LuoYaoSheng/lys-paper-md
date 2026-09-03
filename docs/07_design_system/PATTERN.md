# PaperMD Design System — Patterns（P5）

> 版本：v1.0　日期：2026-09-02
> 内容：交互模式库（文本编辑/快捷键/面板交互/空态）+ 公共参数四件套（快捷键全集·冲突清单·Markdown 支持范围·偏好默认值）。全部真实值注明来源。

---

## 1. 文本编辑模式

### 1.1 Styled-Source 模式（产品根基）

- 标记永远可见（`#`、`**` 不隐藏）；高亮=NSTextStorage 属性叠加，永不改源文本语义（CLAUDE.md P0）。
- 保存内容 = `textView.string` 纯文本（Document.swift L129-137）。

### 1.2 包裹式格式化（inline）

- 选中文字 → 插入前后缀（`**sel**` / `*sel*` / `` `sel` `` / `~~sel~~`）→ 替换后**整段保持选中**（EditorView L487-497）。
- 无选区时除链接外全部禁用（F058 校验）；链接无选区插 `[text](url)` 并选中 "text" 4 字符（EditorView L536-540）。

### 1.3 行首替换式格式化（block）

- 标题：剥离既有 `#` 序列 → 插入新前缀 → 光标置前缀后（EditorView L499-515）。
- 引用：行首插 `> `；代码块：选区包裹 `\n```\n内容\n```\n`，光标在首围栏+2（EditorView L517-525）。

### 1.4 智能列表键位（Enter/Tab/⇧Tab/Backspace）

来源：MarkdownTextView.swift L126-322 + ListMarkerDetector.swift。

| 键 | 条件 | 行为 |
|----|------|------|
| Enter | 列表行且光标后仅空白、项非空 | 插 `\n`+marker（无序同符号 / 有序 n+1. / 任务 `- [ ] `），光标在 marker 后 |
| Enter | 空列表项 | 删 marker 走默认换行（终止列表） |
| Tab | 列表行 | 行首 +2 空格 |
| ⇧Tab | 列表行 | 行首 −2 空格（遇 tab 删 1 个 tab） |
| Backspace | 无选区、光标紧跟空项 marker 后 | 删本行+前一换行（行合并） |
| 任何拦截键 | IME marked text 期间 | 全部放行（L138-141） |
| ⌘ 组合键 | — | 不拦截交菜单（L132-135） |
| ⌘Z / ⇧⌘Z | — | performKeyEquivalent 直调 undoManager（keyCode 6，L174-192） |

### 1.5 粘贴分流模式

- ⌘V：剪贴板含 PNG/TIFF/图片文件 → ImageHandler 落盘插 `![](相对路径)`；否则纯文本替换选区、光标移粘贴文本末尾、禁富文本格式（MarkdownTextView L102-122）。

### 1.6 输入调度模式（性能铁律）

- textDidChange → IME 判断 → `scheduleMarkdownFormatting`（0 延迟 coalesce，合并 editedRange）→ 光标保存/恢复（EditorView L217-323）。
- 大纲/统计异步刷新（DispatchQueue.main.async，L325-330）。

---

## 2. 快捷键模式

### 2.1 修饰键分层（从菜单定义归纳，AppDelegate.swift）

| 修饰层 | 语义 | 例 |
|--------|------|----|
| ⌘X | 应用级标准动作 | ⌘S ⌘F ⌘B |
| ⇧⌘X | 同命令的"变体/反向" | ⇧⌘Z 重做、⇧⌘G 上一个、⇧⌘S 另存、⇧⌘1-6 标题级 |
| ⌥⌘X | 辅助格式/文字变换 | ⌥⌘S 删除线、⌥⌘> 引用、⌥⌘F 替换、⌥⌘H 隐藏其它 |
| ⌃⌘X | 视图/导出（App 专属层） | ⌃⌘O 侧栏、⌃⌘F 专注、⌃⌘E/P 导出 |

### 2.2 新增快捷键规则（V1 起）

- 延续上表分层；B1 新增 ⇧⌘4/5/6 归入"⇧⌘ 变体"层（标题级序列延伸），不改既有键。
- 任何改键（如 C4 ⌥⌘C 双义）必须先过冲突清单（§4.2）并经用户确认。

---

## 3. 面板交互模式

| 模式 | 规格 | 来源 |
|------|------|------|
| 单例复用 | 偏好/查找面板 isReleasedWhenClosed=false，关闭=隐藏语义 | PreferencesWindowController L22、SearchReplaceController L25 |
| 即时生效 | 偏好无"确定/取消"，改动即写 UserDefaults→apply()→广播→全文重排版（光标保持） | PreferencesWindowController L205-224 |
| Sheet 模态 | 导出/保存经 beginSheetModal 挂主窗口 | AppDelegate L390 |
| 目标随 keyWindow | 查找面板每次 ⌘F 重绑当前编辑区 | AppDelegate L359-368 |
| Esc 关闭 | macOS 面板惯例；V1 显式定义（旧版未验证【未知】） | — |
| 撤销可回退 | 面板引发的文本变更必须入 undo 栈（V1 B3 将 Replace All 对齐此模式；旧版例外已记录） | CLAUDE.md P0 规则 4 |

---

## 4. 公共参数一：快捷键全集（40 项，真实值+来源）

> 来源：AppDelegate.swift `fixMenuStructure()` L89-305（keyEquivalent + modifierMask 逐项）；README.md 未列出的项标 **[README 缺]**。

### PaperMD 菜单

| 命令 | 键 | 来源行 |
|------|----|--------|
| About PaperMD | 无 | L103 |
| Preferences… | ⌘, | L106 |
| Hide PaperMD | ⌘H | L108 |
| Hide Others | ⌥⌘H | L109-110 |
| Show All | 无 | L111 |
| Quit PaperMD | ⌘Q | L113 |

### File 菜单

| 命令 | 键 | 来源行 |
|------|----|--------|
| New | ⌘N | L123 |
| Open… | ⌘O | L124 |
| Open Recent（含 Clear Menu） | 无 | L127-133 |
| Close | ⌘W | L138 |
| Save | ⌘S | L139 |
| Save As… | ⇧⌘S | L140 |
| Export to HTML… | ⌃⌘E **[README 缺]** | L149-151 |
| Export to PDF… | ⌃⌘P **[README 缺]** | L153-155 |

### Edit 菜单

| 命令 | 键 | 来源行 |
|------|----|--------|
| Undo | ⌘Z | L169 |
| Redo | ⇧⌘Z | L170 |
| Cut | ⌘X | L172 |
| Copy | ⌘C | L173 |
| Paste | ⌘V | L174 |
| Select All | ⌘A | L175 |
| Find… | ⌘F **[README 缺]** | L179 |
| Find Next | ⌘G **[README 缺]** | L180 |
| Find Previous | ⇧⌘G **[README 缺]** | L181 |
| Replace | ⌥⌘F **[README 缺]** | L182-185 |
| Show Spelling and Grammar | ⌘: **[README 缺]** | L189 |
| Check Document Now | ⌘; **[README 缺]** | L190 |
| Make Upper Case | ⌃⌘U **[README 缺]** | L199-202 |
| Make Lower Case | ⌃⌘L **[README 缺]** | L204-207 |
| Capitalize | ⌥⌘C **[README 缺]** | L209-212 |
| Jump to Selection | ⌘J **[README 缺]** | L218 |

### View 菜单

| 命令 | 键 | 来源行 |
|------|----|--------|
| Toggle Sidebar | ⌃⌘O **[README 缺]** | L228-230 |
| Toggle Focus Mode | ⌃⌘F **[README 缺]** | L231-232 |

### Format 菜单

| 命令 | 键 | 来源行 |
|------|----|--------|
| Bold | ⌘B | L244 |
| Italic | ⌘I | L245 |
| Code | ⌘K | L246 |
| Strikethrough | ⌥⌘S **[README 缺]** | L248-250 |
| Heading 1 / 2 / 3 | ⇧⌘1 / ⇧⌘2 / ⇧⌘3 | L254-259 |
| **Heading 4 / 5 / 6（V1 B1 新增）** | ⇧⌘4 / ⇧⌘5 / ⇧⌘6 | product-review B1 |
| Blockquote | ⌥⌘> **[README 缺]** | L263-265 |
| Code Block | ⌥⌘C **[README 缺]** | L267-269 |
| Insert Link | ⇧⌘L **[README 缺]** | L271-272 |

### Window / Help 菜单

| 命令 | 键 | 来源行 |
|------|----|--------|
| Minimize | ⌘M | L282 |
| Zoom | 无 | L283 |
| Bring All to Front | 无 | L285 |
| PaperMD Help | ⇧⌘? **[README 缺]** | L296 |

**README 缺失合计：19 项**（逆向报告 ⑨-14 称"10+"，实测 19）。

### 4.2 快捷键冲突清单

| 冲突 | 键位 A | 键位 B | 影响 | 处置 |
|------|--------|--------|------|------|
| **⌥⌘C 双义（唯一真冲突）** | Transformations→Capitalize（AppDelegate L209-212） | Format→Code Block（L267-269） | AppKit 匹配其一（通常 Edit 在前），Code Block 快捷键可能永不触发 | **C4** 待用户决策；V1 菜单两处照旧呈现+⚠ 标注 |
| ⌘F（Find）vs ⌃⌘F（Focus） | 无修饰冲突（⌃ 区分） | — | 无 | — |
| ⌥⌘F（Replace）vs ⌘F | 修饰区分 | — | 无 | — |
| ⇧⌘?（Help） | Shift+⌘+/ | — | 无 | — |
| V1 新增 ⇧⌘4/5/6 | 与系统无默认冲突（截图是 ⇧⌘3/5，⇧⌘4 为区域截图——**注意：macOS 系统截图 ⇧⌘4 由系统接管**，App 内菜单项通常仍可响应，但存在系统级竞争【未知——需真机验证】） | — | 潜在系统级竞争 | V1 保留并在评审面板标注该风险 |

---

## 5. 公共参数二：Markdown 语法支持范围枚举

> 来源：MarkdownParser.swift（解析/导出）+ MarkdownFormatter.swift（编辑器高亮）。✔ 支持；◐ 部分支持（注明）；✘ 不支持（无对应代码分支）。

### 块级

| 语法 | 解析 | 高亮 | 导出 | 备注 |
|------|:---:|:---:|:---:|------|
| ATX 标题 #~###### | ✔（L287-295，1-6 级需后跟空格或行尾） | ✔（sizes 6 档，L286-316） | ✔ `<h1-6>` | |
| Setext 标题 ===/--- | ✔（L63-66、L275-284，1/2 级） | ✔（L318-356） | ✔（转 setext 处理） | 下划线行本身解析为 blank |
| 无序列表 -/*/+/ | ✔（L341-344） | ✔ marker 橙 | ✔ `<ul><li>` | 需 marker 后空格 |
| 有序列表 n. | ✔（L346-349） | ✔ marker meta 色 | ✔ `<ol><li>` | |
| 任务列表 - [ ] / - [x] / - [X] | ✔（L351-355） | ✔（完成绿/未完灰，Formatter L542-545） | ✔ checkbox disabled+checked | 仅 `- ` 前缀支持任务检测 |
| 引用 >（可嵌套） | ✔ | ✔ 深度配色阶梯（Formatter L404） | ✔ `<blockquote><p>`（L220-228） | 导出按段落包裹 |
| 围栏代码块 ``` / ~~~ | ✔（L47-50 toggle） | ✔（等宽+语言标识着色） | ✔ `<pre><code>` | 高亮围栏语言标识（Formatter L259-277）；回溯 ≤100 行（L175） |
| 水平线 ---/***/___ | ✔（L303-308） | ✔ hr 色 | ✔ `<hr>` | |
| GFM 表格 | ✔（L310-317 row/separator） | ◐ **旧版无表格高亮**（V1 B4 补） | ✔ thead/tbody（L165-182） | |
| 独立图片行 | ✔（L329-333） | ✔ 淡紫行背景 | ✔ `<img>` | 整行仅图片才识别 |

### 行内

| 语法 | 高亮 | 导出 | 备注 |
|------|:---:|:---:|------|
| 粗体 **text** / __text__ | ✔ bold | ✔ `<strong>` | 行内码区间内不格式化（Formatter L559） |
| 斜体 *text* / _text_ | ✔（斜体四级回退链） | ✔ `<em>` | 回退失败时无视觉斜体（源码事实） |
| 删除线 ~~text~~ | ✔ | ✔ `<del>` | |
| 行内代码 `code` | ✔ 等宽+粉 | ✔ `<code>` | 反引号本身 meta 色弱化 |
| 链接 [text](url) | ✔ 蓝+下划线 | ✔ `<a>` | 分隔符与 url meta 色 |
| 图片 ![alt](url) | ✔ 紫 | ✔（独立行场景） | |
| HTML 标签 `<tag>` | ✔ 棕+等宽 | ✘ 转义输出 | 导出 escapeHTML 后按段落文本呈现 |

### 不支持（无代码分支，防脑补清单）

✘ 脚注 `[^1]`、数学公式 `$...$`、自动链接 `<https://...>`（按 HTML 标签高亮但不语义化）、引用式链接定义 `[a]: url`、表格对齐语法 `:---:`（分隔行整体识别，不解析对齐）、任务列表缩进子项的严格层级、代码块内语法着色（仅等宽+基础色，无语言级 tokenizer）。
范围外（产品明确不做）：隐藏标记 WYSIWYG、脚注/公式属 v2（docs/产品说明.md 5.2.2）。

---

## 6. 公共参数三：偏好项默认值

来源：PreferencesWindowController.swift L239-280。

| UserDefaults 键 | 类型 | 默认值 | UI 档位 | 作用域 |
|------------------|------|--------|---------|--------|
| `editorFontSize` | Int | **16** | 12/13/14/15/16/17/18/20/22/24 pt（L136） | 编辑器基础字号（等宽=−2；标题阶梯为绝对值不联动） |
| `appTheme` | String | **"system"** | light / dark / system（L162-169） | NSAppearance + 高亮色板 + 导出 CSS 三端联动 |
| `autosaveEnabled` | Bool | **true**（L277-279 显式播种） | 复选框 | 3 秒自动保存（仅已保存文档） |

派生行为：启动仅 `applyLaunchSettings()`（套主题不广播，避免编辑器就绪前重排版，L287-290）；变更即 `apply()`（套主题+广播 `.preferencesChanged` → EditorView 全文重排版且光标保持，L282-285）。

---

## 7. 空文档态模式

| 场景 | 旧版行为 | V1 呈现 |
|------|----------|---------|
| 新建文档 | 预填欢迎文本 `# Hello PaperMD\n\nStart typing...`（Document L83） | 照旧（B 类不改） |
| 空大纲 | 纯空列表 | **B8**：引导文案「暂无标题 · 以 # 开始的行将出现在这里」 |
| 状态栏 0 词 | "0 words / 0 characters / 1 min read" | **B7**："0 min read"（修复并注明） |
| 打开空文件 | 空编辑区可立即输入 | 照旧 |
| 打开损坏文件 | 静默空文档 | **B5**：alert「无法以 UTF-8 解码，已打开空文档」 |
