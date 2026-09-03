# PaperMD 重写模块拆分（P7 · module-split）

> 版本：v1.0　日期：2026-09-02
> 输入：P4 公共能力四层识别（product-review §四）+ tech-architecture 分层 + api-design 契约。
> 目标目录结构给出迁移映射（旧文件 → 新模块），确保 60 项功能与测试资产零丢失。

---

## 1. 目标模块结构

```
PaperMD/
├── App/                          # App Shell（AppKit）
│   ├── AppDelegate.swift         # 菜单配置装载/窗口保活/面板持有（含 FeedbackCenter 接线）
│   ├── main.swift                # 启动入口（显式 delegate，无 storyboard）
│   ├── PaperMDDocumentController.swift
│   ├── MenuSpec.swift            # 【新】菜单数据化（api-design §8；归位 CF-05，C4 冲突登记）
│   └── FeedbackCenter.swift      # 【新】B5/B6 载体（CP-11：toast/alert/查找状态行）
├── Document/                     # 文档层
│   ├── Document.swift            # NSDocument 子类（读写/自动保存/迁移钩子；decode 失败改 Result）
│   └── PersistenceStore.swift    # 【新】UTF-8 原子读写（归位 SV-04）
├── Editor/                       # 编辑 UI + 引擎
│   ├── EditorScene.swift         # 原 EditorView（大纲+编辑+状态栏布局；调度逻辑移出）
│   ├── MarkdownTextView.swift    # 键盘智能编辑/纯文本粘贴/拖拽（保留）
│   ├── EditorEngine.swift        # 【新】格式化统一实现 + 调度状态机（归位 D1 三处重复）
│   └── OutlineView.swift / StatusBar.swift
├── Panels/                       # 面板
│   ├── FindReplacePanel.swift    # 原 SearchReplaceController（+FindSession/计数/Esc；单例修复）
│   └── SettingsPanel.swift       # 原 PreferencesWindowController（D2 措辞；Model 移 Core）
├── Core/                         # 领域层（Foundation-only，可测试）
│   ├── MarkdownParser.swift / ListMarkerKit.swift（原 ListMarkerDetector，A2 修复）
│   ├── MarkdownHighlighter.swift # 原 MarkdownFormatter（实例化+主题注入；B4 表格分支）
│   ├── SearchService.swift       # 原 TextSearch（B2/B3/B6 行为升级）
│   ├── MarkdownTheme.swift       # 色板+导出 CSS（CF-01）
│   └── DebugLog.swift
├── Services/
│   ├── AssetService.swift        # 原 ImageHandler（SV/MD-06）
│   ├── ExportService.swift       # 原 ExportHelper（渲染完成回调时序）
│   └── PreferencesStore.swift    # 原 Preferences（SV-01）
└── Supporting Files/             # Info.plist / entitlements（Main.storyboard 移除→C7）
```

## 2. 公共能力归位映射（P4 四层 → 模块）

| 公共能力 | 旧位置（分散） | 新归位 | 收益 |
|----------|----------------|--------|------|
| CP-01 主窗口框架 | Document.openEditorWindow | Document/ + App/ | — |
| CP-02 菜单栏 | AppDelegate.fixMenuStructure（300 行内联） | App/MenuSpec.swift（数据驱动） | 快捷键全集单一来源（patterns §4.1）；C4 冲突可标注 |
| CP-03 工具栏 | WindowController.setupToolbar | Editor/WindowController + MenuSpec 快捷键共享 | B1 Heading 下拉 |
| CP-04 大纲 | OutlineView | Editor/OutlineView | B8 空态 |
| CP-05 编辑区 | EditorView+MarkdownTextView+MarkdownFormatter | Editor/ 三件（Scene/TextView/Engine）+ Core/Highlighter | D1 消除三处重复 |
| CP-06 状态栏 | StatusBar+DocumentStats | Editor/StatusBar | B7 |
| CP-07 查找面板 | SearchReplaceController+TextSearch | Panels/FindReplacePanel + Core/SearchService | B2/B3/B6；单例修复（state-management §5） |
| CP-08 偏好 | PreferencesWindowController（Model 内嵌） | Panels/SettingsPanel + Services/PreferencesStore | UI/存储分离 |
| CP-09 系统面板 | AppDelegate/Document/ExportHelper 内联 | Document/ + Services/ExportService | B5 失败反馈统一 |
| CP-10 专注模式 | EditorView+WindowController | Editor/EditorScene | — |
| CP-11 反馈组 | 无（旧版静默） | App/FeedbackCenter | B5/B6 唯一出口 |
| CP-12 撤销组 | ImageHandler.ImageInsertUndoHandler | Services/AssetService（+ReplaceAll 组入 EditorEngine） | B3 |
| MD-01 编辑引擎 | EditorView 调度段 | Editor/EditorEngine.swift | C6 UTF-16 一致性修复点 |
| MD-02 高亮 | MarkdownFormatter（静态+全局态） | Core/MarkdownHighlighter（实例+注入） | 主题/字号显式依赖 |
| MD-03 解析 | MarkdownParser | Core/（原样迁移） | 测试零改动 |
| MD-04 智能列表 | MarkdownTextView+ListMarkerDetector | Editor/MarkdownTextView + Core/ListMarkerKit | A2 空项修复 |
| MD-05 查找 | TextSearch | Core/SearchService | throws 化（B5-④） |
| MD-06 图片 | ImageHandler | Services/AssetService | — |
| MD-07 导出 | ExportHelper+PrintableMarkdownView | Services/ExportService | 渲染时序显式 |
| SV-01 偏好存储 | Preferences | Services/PreferencesStore | — |
| SV-02 自动保存 | Document.startAutosaveTimer | Document/（失败→FeedbackCenter） | B5-② |
| SV-03 撤销系统 | NSUndoManager 散用 | EditorEngine+AssetService 分组规范 | state-management §3 |
| SV-04 持久化 | Document.read/data | Document/PersistenceStore | B5-⑦ Result 化 |
| SV-05 统计 | DocumentStats | Editor/StatusBar（随 CP-06） | B7 |
| SV-06 日志 | DebugLog | Core/（原样） | — |
| CF-01 主题 | MarkdownTheme | Core/MarkdownTheme | — |
| CF-02 偏好默认值 | Preferences.init | Services/PreferencesStore | 键名兼容 |
| CF-03 窗口尺寸 | 三处字面量 | App/Constants（800×600/450×300/420×160） | tokens.md §3 单一来源 |
| CF-04 工具栏序列 | WindowController L182-194 | Editor/WindowController + MenuSpec | — |
| CF-05 菜单/快捷键 | AppDelegate L89-305 | App/MenuSpec | — |
| CF-06 欢迎文本/命名规则 | Document L83、ImageHandler | App/Constants | — |

## 3. 依赖规则（import 纪律）

```
App ──► Document ──► Editor ──► Core
 │          │           │
 └── Panels ┘           └──► Services ──► Core
规则：Core 不 import AppKit（保持 Foundation-only 可移植测试）；
     Services 不依赖 Editor；Editor 不直接触 UserDefaults（经 PreferencesStore）；
     全部失败路径经 FeedbackCenter，禁止裸 NSLog 面向用户路径（DebugLog 仅保留开发日志）。
```

## 4. 迁移与删除清单

| 动作 | 对象 | 依据 |
|------|------|------|
| 原样迁移 | Core/MarkdownParser、DebugLog、ListMarkerDetector（改 ListMarkerKit）、TextSearch（升级）、MarkdownTheme、PaperMDTests 13 文件、PaperMDUITests 5 文件、Tests/ 手工清单 | 逆向 ⑧/附 |
| 重构迁移 | EditorView→Scene+Engine、MarkdownFormatter→Highlighter、ImageHandler→AssetService、ExportHelper→ExportService、Preferences→Store+Panel | 本文件 §2 |
| **删除** | Supporting Files/Main.storyboard（C7：运行时已被 fixMenuStructure 覆盖；删除后 pbxproj 资源引用同步清理） | 逆向 1.2 注意 |
| **删除** | WindowController.togglePreview 空壳（C1：或保留占位——待用户决策，默认删除） | P4 F-09 |
| **删除** | MenuActions.swift（反射取 textView 的备用路径，被 EditorEngine 取代） | P4 F-08 |
| 修复保留 | MarkdownTextView.performKeyEquivalent ⌘Z 直调；IME 放行；undoManager 回退链 | state-management §3.3 |

## 5. 分期交付对齐

| 里程碑（tech-architecture §6） | 模块 | 验收 |
|-------------------------------|------|------|
| M1 | App/Document/Editor/Core 骨架 | 旧单测全绿 + INPUT_REGRESSION_CHECKLIST P0 14 项 |
| M2 | FeedbackCenter、FindPanel、B1/B4/B7/B8 | v1-acceptance B 类核验表逐项映射 |
| M3 | Services（Asset/Export/Preferences） | ImageHandler/ExportHelper/DocumentLaunch 测试迁移全绿 |
| M4（C5 通过后） | EditorEngine 的 TextKit 2 实现 | Spike 基准 + 零 P0 回归门槛（TEXTKIT2_SPIKE.md） |
