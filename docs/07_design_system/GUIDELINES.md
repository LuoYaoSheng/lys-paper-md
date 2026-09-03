# PaperMD Design System — Guidelines（P5）

> 版本：v1.0　日期：2026-09-02
> 定位：Design System 使用守则。五文件体系：tokens（值）→ components（组件）→ patterns（模式与公共参数）→ assets（图标）→ guidelines（本文件，规则与流程）。

---

## 1. 值可溯源原则

1. 一切样式值以 `tokens.md` 为唯一入口，且必须有源码出处（文件+行号）；无出处的新值禁止入库。
2. 系统动态色（NSColor 系统语义色）保留语义名，CSS 近似值仅用于 HTML 原型并标 `≈`。
3. 源码事实与设计直觉冲突时，**先记录事实再谈改进**：改进一律挂 B/C/D 编号（见 docs/06_review/PRODUCT_REVIEW.md），不静默改值。
   - 例：标题字号阶梯 [28,24,20,18,17,16] 为绝对值、不随基础字号联动（MarkdownFormatter.swift L292）——作为事实保留；是否改为比例字号属新决策，未立项。

## 2. 主题双轨原则

1. Light / Dark 双主题全覆盖：任何新组件必须同时给出两主题表现，且颜色引用 token（系统动态色自动适配；固定色必须显式给两态值，参照 imageLineBackground 8%/15% 双值先例）。
2. `system` 态跟随 NSApp.effectiveAppearance（MarkdownTheme.swift L95-105）；原型以 body.theme-light / theme-dark 两 class 模拟。
3. 主题三端联动检查：编辑器色板（MarkdownTheme.Colors）→ App 外观（NSAppearance）→ 导出 CSS（MarkdownTheme.css）。改一处必查三处。

## 3. 组件使用守则

1. 优先复用 components.md 已登记组件；新组件必须走「组件记录表」（职责/结构/尺寸/字体/状态机/输入输出/禁用边界/来源）。
2. 通用原子控件（NSButton/NSPopUpButton/NSTextField/复选框）用系统默认样式，不自绘、不换肤——App 原生感是产品主张（README 核心特性 1）。
3. 面板遵循 patterns.md §3 模式：单例复用、即时生效、sheet 模态、Esc 关闭、变更入撤销栈。
4. 反馈组件（CP-11）复用既有 token，不新增语义色（防止色板漂移）。

## 4. 快捷键守则

1. 新增/修改快捷键必须对照 patterns.md §4.1 全集与 §4.2 冲突清单；与既有键冲突或依赖系统级键位（如 ⇧⌘4 截图竞争）时标【未知/风险】并升 C 类待用户确认。
2. 修饰键分层（⌘ 应用级 / ⇧⌘ 变体 / ⌥⌘ 辅助 / ⌃⌘ 视图导出）不可混用。
3. README 快捷键表已滞后 19 项（patterns.md §4.1 实测）——重写期文档以 §4.1 全集为准。

## 5. V1 原型硬性约束（对 prototype/v1-new 生效）

1. CSS 变量必须 1:1 映射 tokens.md（§5 映射约定）；组件样式只准 `var(--token)`，禁止裸值。
2. 60 项功能不得丢失：保留或按 product-review C 类留档；禁止私加商业功能（云同步/AI/账号/插件等 CLAUDE.md Out of scope 项）。
3. 旧版 bug 行为不得复制：V1 呈现修复后规格并在界面注明差异（B3 撤销、B7 阅读时间、B5 静默失败等）。
4. 每视图标注「编号+来源」（PAGE/F/B 编号）；单文件零外链；五态齐全（Loading/Empty/Error/Success/Permission）；macOS 窗口画框含菜单栏示意+评审面板。
5. `node --check` 必须通过（提取内嵌 script 校验）。

## 6. DS 演进流程

```
新需求 → 判定分级（P4 product-review：A 勘误 / B 优化 / C 决策 / D 观察）
  ├─ A：改文档+登记（docs/06_review/PRODUCT_REVIEW.md §6）
  ├─ B：tokens（若需新值）→ components（记录表）→ patterns（若新模式）→ V1 原型呈现 → v1-acceptance 核验
  ├─ C：留档待用户确认，不进 DS
  └─ D：观察不动，仅在 product-review 记录
```

## 7. 与其它产物的引用关系

| 产物 | 关系 |
|------|------|
| docs/01_reverse/REVERSE_ANALYSIS.md | 事实源（本 DS 全部值的最终依据） |
| docs/02_product/PRD.md / docs/02_product/PAGE_SPEC.md | 需求与交互规格（DS 为其视觉/参数层） |
| docs/06_review/PRODUCT_REVIEW.md | 分级处置入口（B 类驱动 DS 变更） |
| prototype/v0-old/ | 旧版原型（复刻基线，不再演进） |
| prototype/v1-new/ | V1 原型（本 DS 的首个完整消费者） |
| docs/04_architecture/ | P7 架构（模块拆分消费 components/patterns 的公共能力四层） |
