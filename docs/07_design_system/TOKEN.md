# PaperMD Design System — Tokens（P5）

> 版本：v1.0　日期：2026-09-02
> 提取原则：**全部取自旧项目 Swift 源码真实样式值**，每项注明来源文件与行号；系统动态色（NSColor.systemXxx）给出语义名 + CSS 原型近似值（近似值仅用于 HTML 原型，以 `≈` 标注）。
> 主题：双主题 Light / Dark（`MarkdownThemeStyle`，MarkdownTheme.swift L8-12），`system` 态跟随 NSApp.effectiveAppearance（L95-105）。
> 适用范围：V1 新版原型（prototype/v1-new/）的全部 CSS 变量必须且只能引用本文件 token。

---

## 1. Color Tokens

### 1.1 编辑器语法色板（11 语义色 × 双主题）

来源：`PaperMD/Core/MarkdownTheme.swift` L35-66（`Colors(for:)`）。注意：**除 imageLineBackground 外，Light/Dark 使用同一组 NSColor 系统色**（系统色自带明暗自适应）。

| Token | 语义 | 来源值（NSColor） | Light 近似 | Dark 近似 | 消费方 |
|-------|------|-------------------|-----------|----------|--------|
| `--syntax-heading` | ATX/Setext 标题文字 | systemBlue（L39/L52） | ≈#0366d6 | ≈#7db4ff | 高亮引擎·标题行 |
| `--syntax-code` | 行内代码文字 / 围栏语言标识 | systemPink（L40/L53） | ≈#d63384 | ≈#f8a8d8 | 高亮引擎 |
| `--syntax-link` | 链接显示文字 | systemBlue（L41/L54） | ≈#0a66c2 | ≈#7db4ff | 高亮引擎·[text] |
| `--syntax-image` | 图片 alt 文字 | systemPurple（L42/L55） | ≈#6f42c1 | ≈#b78cf2 | 高亮引擎·![alt] |
| `--syntax-list-marker` | 无序列表标记 -/*/+ | systemOrange（L43/L56） | ≈#d97706 | ≈#f0a35e | 高亮引擎 |
| `--syntax-quote` | 引用内容（深度 2） | systemTeal（L44/L57） | ≈#0d9488 | ≈#6fd3c8 | 高亮引擎 |
| `--syntax-meta` | 次要标记（#前缀/反引号/分隔符/有序标记/围栏行） | secondaryLabelColor（L45/L58） | ≈#9aa0a6 | ≈#7c7c82 | 高亮引擎 |
| `--syntax-hr` | 水平线 ---/***/___ | separatorColor（L46/L59） | ≈#c9c9c9 | ≈#4a4a4a | 高亮引擎 |
| `--syntax-html-tag` | HTML 标签整体 | systemBrown（L47/L60） | ≈#8b5a2b | ≈#c99a6b | 高亮引擎 |
| `--syntax-task` | 未完成任务标记 [ ] | systemGray（L48/L61） | ≈#6b7280 | ≈#9a9aa2 | 高亮引擎 |
| `--syntax-task-done` | 已完成任务标记 [x] | systemGreen（MarkdownFormatter.swift L543，硬编码非色板） | ≈#1f9d55 | ≈#4cd964 | 高亮引擎 |
| `--syntax-image-line-bg` | 独立图片行背景 | systemPurple α0.08（light L63）/ α0.15（dark L49） | ≈rgba(111,66,193,.08) | ≈rgba(183,140,242,.15) | 高亮引擎 |

引用深度配色阶梯（MarkdownFormatter.swift L404）：`[labelColor, quoteColor, systemGreen, systemOrange]` 按嵌套深度取（深度>4 钳制到最后档）。

### 1.2 导出 CSS 真实值（HTML/PDF 交付主题）

来源：`MarkdownTheme.css(for:)` L68-93（导出 HTML 内嵌样式，值为源码字面量，非近似）。

| Token | Light（源码字面量） | Dark（源码字面量） | 用途 |
|-------|--------------------|--------------------|------|
| `--export-body-bg` | 未设置（浏览器默认白） | `#1e1e1e` | 导出页背景 |
| `--export-body-fg` | 未设置 | `#e8e8e8` | 导出页正文 |
| `--export-link` | `#0066cc` | `#7db4ff` | 导出链接 |
| `--export-code-bg` | `#f4f4f4` | `#2d2d2d` | 行内码/代码块背景 |
| `--export-code-fg` | 未设置 | `#f8a8d8` | 代码文字（仅暗色定义） |
| `--export-quote-border` | `#ddd` | `#555` | 引用左边框 |
| `--export-quote-fg` | `#666` | `#aaa` | 引用文字 |
| `--export-hr` | `#eee` | `#444` | 分隔线 |
| `--export-h-border` | `#eee`（仅 h1,h2 下边框，L84） | 无 | 标题下划线（仅亮色） |

导出排版常量（同源）：`max-width:800px; margin:40px auto; padding:0 20px; line-height:1.6`（L72/L83）；`pre{padding:1em; border-radius:5px}`；`code{padding:0.2em 0.4em; border-radius:3px}`；`blockquote{border-left:4px solid; padding-left:1em}`；`hr{margin:2em 0}`；`h1-h6{margin-top:1.5em}`（暗色）；`img{max-width:100%}`。

### 1.3 App UI 基础色（系统动态色语义名）

来源：各 App 层文件（标注处）。CSS 原型近似值与 v0 原型对齐（prototype/v0-old/app-prototype.html :root 块）。

| Token | 来源 | Light 近似 | Dark 近似 | 用途 |
|-------|------|-----------|----------|------|
| `--bg-window` | NSWindow 默认（windowBackgroundColor，PreferencesView L63 用于偏好窗） | ≈#ffffff | ≈#1e1e1e | 窗体 |
| `--bg-control` | controlBackgroundColor（OutlineView L37、StatusBar L34） | ≈#ebebeb | ≈#232325 | 侧栏/状态栏 |
| `--bg-editor` | textBackgroundColor（EditorView L129） | ≈#ffffff | ≈#1e1e1e | 编辑区 |
| `--fg-label` | labelColor（Formatter L97 基础文字） | ≈#1b1b1b | ≈#e8e8e8 | 正文/主文字 |
| `--fg-secondary` | secondaryLabelColor（StatusBar L80 等） | ≈#666 | ≈#999 | 状态栏/标签 |
| `--separator` | separatorColor（StatusBar L89 分隔线 1pt） | ≈#c9c9c9 | ≈#4a4a4a | 分隔线 |
| `--accent` | 无源码对应（原型评审用强调色，v0 原型 #2f6fd8） | #2f6fd8 | #2f6fd8 | 仅原型：选中高亮/按钮 |
| `--overlay` | 无源码对应（App 用系统 sheet/模态，原型层遮罩） | ≈rgba(0,0,0,.28) | ≈rgba(0,0,0,.5) | 仅原型：模态遮罩 |

> `--accent` 为原型层 token，App 内选中效果为系统控件色（keyboardFocusIndicatorColor 系统托管），源码无字面量【未知——未在源码找到显式 accent 定义】。

---

## 2. Typography Tokens

来源：`MarkdownFormatter.swift` L14-60（字体计算）、`OutlineView.swift` L129-135、`StatusBar.swift` L79、`PreferencesWindowController.swift` L112。

### 2.1 字族

| Token | 来源值 | 说明 |
|-------|--------|------|
| `--font-ui` | NSFont.systemFont（全 UI 默认） | CSS 近似：`-apple-system, BlinkMacSystemFont, "PingFang SC", sans-serif` |
| `--font-mono` | NSFont.monospacedSystemFont（Formatter L54-56） | CSS 近似：`"SF Mono", Menlo, Consolas, monospace` |
| `--font-italic-fallback` | Menlo-Italic → Monaco-Italic → Courier-Oblique → Helvetica-Oblique → systemFont（Formatter L33-52 回退链） | 斜体四级回退；全失败时回落正体 |

### 2.2 字号阶梯（基础字号 base=偏好值，默认 16，12-24 十档）

| Token | 计算式 | 来源 |
|-------|--------|------|
| `--fs-base` | base（默认 16） | PreferencesWindowController L136 sizes=[12,13,14,15,16,17,18,20,22,24] |
| `--fs-bold` | base（boldSystemFont） | Formatter L29-31 |
| `--fs-mono` | base − 2 | Formatter L54-56（行内码/代码块/HTML 标签） |
| `--fs-h1` ~ `--fs-h6` | **绝对值 [28,24,20,18,17,16]**，bold | Formatter L292（不随 base 缩放，源码事实） |
| `--fs-setext-h1/h2` | 28 / 24，bold | Formatter L346-350 |
| `--fs-outline-h1/h2/h3+` | bold14 / bold13 / 13 | OutlineView L129-135 |
| `--fs-status` | 11，secondaryLabel | StatusBar L79 |
| `--fs-pref-section` | bold13 | PreferencesWindowController L112 |
| `--fs-menu` | 系统菜单默认 13pt（AppKit 托管，源码未显式设置【未知精确值】） | — |

### 2.3 字重/装饰

| Token | 值 | 来源 |
|-------|----|------|
| `--fw-heading` | bold（标题/引用标记/引用下划线行） | Formatter L58-60、L354 |
| `--deco-link` | underline single | Formatter L720 |
| `--deco-strike` | strikethrough single | Formatter L603 |
| `--deco-code-dim` | 反引号/分隔符 meta 色弱化 | Formatter L616-621 |

---

## 3. Spacing Tokens

| Token | 值 | 来源 |
|-------|----|------|
| `--win-main-size` | 800×600 主屏居中 | Document.swift L63、L115-123 |
| `--win-pref-size` | 450×300 居中 | PreferencesWindowController L16 |
| `--win-find-size` | 420×160 居中 | SearchReplaceController L19 |
| `--sidebar-width` | 200pt（初始/还原；折叠 0） | EditorView L95、L154、L378-390 |
| `--statusbar-height` | 28pt | EditorView L157 |
| `--statusbar-pad-x` | 12 | StatusBar L40 edgeInsets left/right |
| `--statusbar-gap` | 20（元素间距） | StatusBar L39 |
| `--statusbar-sep-width` | 1pt | StatusBar L91 |
| `--pref-margin` | 20（外边距）；节内边距 24；节间距 16；组内距 8；行距 12 | PreferencesWindowController L68-69、L97-102、L109、L126 |
| `--find-margin` | 16（四边）；行距 10；按钮距 8；标签宽 60 | SearchReplaceController L37-38、L54、L73 |
| `--outline-row-gap` | 4pt（intercellSpacing height） | OutlineView L49 |
| `--outline-cell-pad` | 4（左右）；缩进 = 16×(level−1) | OutlineView L116-120 |
| `--editor-min-width` | 100pt 内容最小宽 | EditorView L119 |
| `--anim-focus` | 0.25s（侧栏折叠动画） | EditorView L368 |
| `--autosave-interval` | 3.0s | Document.swift L193 |
| `--outline-scroll-cursor-delay` | 0.1s（跳转后光标收缩） | EditorView L353 |

---

## 4. Radius Tokens

| Token | 值 | 来源 |
|-------|----|------|
| `--radius-export-pre` | 5px | MarkdownTheme.css L75/L87（导出真实值） |
| `--radius-export-code` | 3px | MarkdownTheme.css L85（导出真实值） |
| `--radius-window` | 10px | macOS 系统窗口圆角（原型层近似；App 由系统托管【源码无字面量】） |
| `--radius-menu` | 6px | 原型层近似（NSMenu 系统托管） |
| `--radius-chip/btn` | 4-6px | 原型层近似（NSButton 系统托管） |

> 原则：App 原生控件圆角全部系统托管，源码真实值仅存在于导出 CSS（5px/3px）；其余 radius 为 HTML 原型的视觉近似 token。

---

## 5. V1 CSS 变量映射约定（供 prototype/v1-new 强制执行）

```
:root / body.theme-light / body.theme-dark 三段式定义
── 必须 1:1 对应上表 token 名（--syntax-* / --export-* / --bg-* / --fg-* / --fs-* / --fw-* / --deco-* /
   --sidebar-width / --statusbar-height / --anim-focus 等）
── 组件样式只允许引用 var(--token)，不得出现裸色值/裸字号
── B 类新增反馈样式（toast/alert/计数行）复用 --bg-control/--fg-secondary/--accent/--separator，
   不新增语义 token（避免 DS 漂移）
```
