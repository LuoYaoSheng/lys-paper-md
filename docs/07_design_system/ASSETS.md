# PaperMD Design System — Assets（P5）

> 版本：v1.0　日期：2026-09-02
> 内容：内联 SVG 关键图标库（菜单栏/工具栏示意）。旧 App 图标全部使用 SF Symbols 系统资源（WindowController.swift，无自绘资产文件——`PaperMD/` 下不存在 .svg/.png 图标资源，工程内唯一图片为 Assets.xcptassets 默认 App 图标【未在源码树发现定制图标，标未知】）。
> 因此本文件的角色：**为 SF Symbols 提供等义 SVG**，供 V1 HTML 原型与后续自绘需求使用；每个 SVG 给出对应 SF Symbol 名与来源行号。SVG 均 24×24 viewBox、stroke=currentColor、零外链。

---

## 1. 工具栏图标（7 枚，来源 WindowController.swift L91-158）

### 1.1 Sidebar（SF: sidebar.left，L91）

```svg
<svg viewBox="0 0 24 24" width="20" height="20" fill="none" stroke="currentColor" stroke-width="1.6" stroke-linecap="round">
  <rect x="3" y="4" width="18" height="16" rx="2"/>
  <line x1="9" y1="4" x2="9" y2="20"/>
</svg>
```

### 1.2 Bold（SF: bold，L107）

```svg
<svg viewBox="0 0 24 24" width="20" height="20" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
  <path d="M7 5h6a3.5 3.5 0 0 1 0 7H7z"/>
  <path d="M7 12h7a3.5 3.5 0 0 1 0 7H7z"/>
</svg>
```

### 1.3 Italic（SF: italic，L115）

```svg
<svg viewBox="0 0 24 24" width="20" height="20" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round">
  <line x1="10" y1="5" x2="15" y2="5"/>
  <line x1="9" y1="19" x2="14" y2="19"/>
  <line x1="14" y1="5" x2="10" y2="19"/>
</svg>
```

### 1.4 Code（SF: chevron.left.forwardslash.chevron.right，L127）

```svg
<svg viewBox="0 0 24 24" width="20" height="20" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round">
  <polyline points="8 8 4 12 8 16"/>
  <polyline points="16 8 20 12 16 16"/>
  <line x1="13.5" y1="7" x2="10.5" y2="17"/>
</svg>
```

### 1.5 Heading（SF: textformat.size，L137）——V1 B1 加层级下拉箭头

```svg
<!-- 基础形态（旧版固定 H1） -->
<svg viewBox="0 0 24 24" width="20" height="20" fill="none" stroke="currentColor" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round">
  <path d="M4 7v10M9 7v10M4 12h5"/>
  <path d="M14 17l4-10 4 10M15.4 13.5h5.2"/>
</svg>
<!-- V1 变体：右下角加层级角标（B1 下拉入口示意） -->
<svg viewBox="0 0 24 24" width="20" height="20" fill="none" stroke="currentColor" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round">
  <path d="M4 6v9M8.5 6v9M4 10.5h4.5"/>
  <path d="M12.5 15l3-3.6 3 3.6"/>
  <path d="M12.5 18.5h6" opacity=".0"/>
</svg>
```

### 1.6 Quote（SF: text.quote，L147）

```svg
<svg viewBox="0 0 24 24" width="20" height="20" fill="none" stroke="currentColor" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round">
  <path d="M5 15c0-4 2-7 5-8"/>
  <path d="M6 15c0-2 1-3.5 2.5-4.2"/>
  <path d="M13 15c0-4 2-7 5-8"/>
  <path d="M14 15c0-2 1-3.5 2.5-4.2"/>
  <line x1="5" y1="18.5" x2="19" y2="18.5"/>
</svg>
```

### 1.7 Code Block（SF: curlybraces，L157）

```svg
<svg viewBox="0 0 24 24" width="20" height="20" fill="none" stroke="currentColor" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round">
  <path d="M8.5 4C6.5 4 7 8 5 8c2 0 1.5 4 3.5 4"/>
  <path d="M8.5 12c-2 0-1.5 4-3.5 4 2 0 1.5 4 3.5 4" transform="translate(1,-8)"/>
  <path d="M15.5 4c2 0 1.5 4 3.5 4-2 0-1.5 4-3.5 4"/>
  <path d="M15.5 12c2 0 1.5 4 3.5 4-2 0-1.5 4-3.5 4" transform="translate(-1,-8)"/>
</svg>
```

---

## 2. 窗口红绿灯与状态点

### 2.1 红绿灯三键（macOS 系统控件示意，原型层）

```svg
<!-- close #ff5f57 / min #febc2e / zoom #28c840，12px 圆 -->
<svg viewBox="0 0 36 12" width="36" height="12">
  <circle cx="6"  cy="6" r="6" fill="#ff5f57"/>
  <circle cx="18" cy="6" r="6" fill="#febc2e"/>
  <circle cx="30" cy="6" r="6" fill="#28c840"/>
</svg>
```

### 2.2 未保存编辑点（NSDocument 标题标记，原型层）

```svg
<svg viewBox="0 0 8 8" width="8" height="8"><circle cx="4" cy="4" r="4" fill="var(--syntax-list-marker)"/></svg>
```

> 旧版为系统绘制的"已编辑"圆点（NSDocument 机制，Document.swift updateChangeCount 路径）；色值原型近似取 --syntax-list-marker（systemOrange）。

---

## 3. V1 反馈组件图标（B5/B6 载体，原型层新增）

```svg
<!-- toast-info（自动保存反馈） -->
<svg viewBox="0 0 16 16" width="14" height="14" fill="none" stroke="currentColor" stroke-width="1.5">
  <circle cx="8" cy="8" r="6.5"/><line x1="8" y1="7" x2="8" y2="11.5"/><circle cx="8" cy="4.6" r="0.4" fill="currentColor"/>
</svg>
<!-- alert-error（导出/打开失败，exclamationmark.triangle 近似） -->
<svg viewBox="0 0 16 16" width="14" height="14" fill="none" stroke="currentColor" stroke-width="1.5" stroke-linejoin="round">
  <path d="M8 2.2 14.6 13.4H1.4z"/><line x1="8" y1="6" x2="8" y2="9.6"/><circle cx="8" cy="11.6" r="0.4" fill="currentColor"/>
</svg>
<!-- find-status（查找面板状态行，magnifyingglass 近似） -->
<svg viewBox="0 0 16 16" width="14" height="14" fill="none" stroke="currentColor" stroke-width="1.5" stroke-linecap="round">
  <circle cx="7" cy="7" r="4.5"/><line x1="10.5" y1="10.5" x2="13.5" y2="13.5"/>
</svg>
```

---

## 4. 菜单栏示意（PAGE002 原型层）

```svg
<!-- Apple 近似（原型菜单栏左端，非商标复刻，仅占位示意） -->
<svg viewBox="0 0 16 16" width="14" height="14" fill="currentColor">
  <path d="M11.2 8.6c0-1.9 1.6-2.8 1.6-2.9-.9-1.3-2.2-1.4-2.7-1.5-1.2-.1-2.2.7-2.7.7s-1.5-.7-2.4-.7C3.9 4.2 2.7 5 2 6.3c-1.4 2.5-.4 6.2 1 8.2.7 1 1.5 2.1 2.5 2 1-.1 1.4-.6 2.6-.6s1.5.6 2.5.6 1.8-1 2.5-2c.4-.6.9-1.4 1.2-2.4-2.3-.9-2.1-3.4-2.1-3.5zM9.4 3.1c.5-.6.8-1.5.7-2.4-.8 0-1.7.5-2.3 1.1-.5.6-.9 1.5-.7 2.3.9.1 1.8-.4 2.3-1z"/>
</svg>
```

> 菜单栏本体（7 菜单文字+快捷键右对齐+子菜单 ▸）由原型 HTML/CSS 构成，无独立图片资产。

---

## 5. 使用规则

1. 原型中所有图标一律内联 SVG（零外链、零 data-URL 图片请求）；fill/stroke 用 `currentColor` 或 token 变量，随主题联动。
2. App 端（P7 重写期）仍建议优先 SF Symbols（免维护、自动适配字重与明暗）；本 SVG 库用于 HTML 原型、文档示意与无法使用 SF Symbols 的场合。
3. 新增图标必须先在本文登记（编号+SF 对应+来源），再进入原型/代码——防止资产漂移。
4. 禁止引入第三方图标库或外链 CDN（V1 铁律：单文件零外链）。
