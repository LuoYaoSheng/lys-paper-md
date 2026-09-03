# PaperMD 项目上下文（PROJECT_CONTEXT）

> 版本：v1.0　日期：2026-09-03
> 事实来源：`docs/01_reverse/REVERSE_ANALYSIS.md`（①项目概述、②项目结构分析）、`PaperMD.xcodeproj/project.pbxproj`、`PaperMD/App/main.swift`、`PaperMD/Supporting Files/Info.plist`、`README.md`、`CLAUDE.md`、`.github/workflows/`
> 说明：本文件为《旧 App AI 重构 SOP v2.0》00_context 阶段产物，只汇总既有事实，不新增结论；未证实处标【未知】。

---

## 1. 项目定位

PaperMD 是一款专为 macOS 设计的原生 Markdown **语法高亮编辑器**，保留源码可见（`#`、`**` 等标记不隐藏），以「极致输入体验」为最高优先级，面向长文写作、文档编写与技术写作。本地优先：文件即文档，无私有格式，无云端依赖。（来源：`docs/01_reverse/REVERSE_ANALYSIS.md` ①1.1，原始出处 `README.md`、`CLAUDE.md`）

- 编辑模型：单栏「带样式的源码」（styled source）——Markdown 标记保持可见，语法高亮以属性叠加方式呈现；不是 Typora 式隐藏标记的 WYSIWYG。（来源：同上）
- 产品四铁律（P0，来源 `README.md` 开发理念 / `CLAUDE.md`）：① 光标永不因渲染跳动；② 自动格式化绝不移动光标；③ 中文 IME 组合期间不进行布局重建；④ 每个结构变更（含图片插入）必须可撤销。
- v1 明确不做：云同步、协作、插件、AI 写作、账号体系。（来源：`CLAUDE.md` Out of scope、`docs/产品说明.md` 第 9 节）

## 2. 仓库布局（顶层）

```
PaperMD/
├── PaperMD.xcodeproj/            # Xcode 工程（scheme: PaperMD；targets: PaperMD / PaperMDTests / PaperMDUITests）
├── PaperMD/
│   ├── App/                      # UI 层 + 应用层（15 个 .swift，全部 import Cocoa/AppKit）
│   │   ├── main.swift            # 启动入口：显式挂接 AppDelegate（移除 Main.storyboard 启动）
│   │   ├── AppDelegate.swift     # 菜单程序化重建/窗口保活/偏好、查找、导出入口
│   │   ├── PaperMDDocumentController.swift  # NSDocumentController 子类（新建文档直开窗口）
│   │   ├── Document.swift        # NSDocument 子类：读写/保存/自动保存/窗口创建
│   │   ├── WindowController.swift          # 窗口控制器 + NSToolbar（7 工具项）
│   │   ├── EditorView.swift      # NSSplitView(大纲+编辑区)+状态栏；格式化调度
│   │   ├── MarkdownTextView.swift         # NSTextView 子类：智能列表键、纯文本粘贴、图片拖放
│   │   ├── OutlineView.swift / StatusBar.swift / SearchReplaceController.swift
│   │   ├── ExportHelper.swift / ImageHandler.swift / MenuActions.swift
│   │   ├── MarkdownFormatter.swift        # 行级增量语法高亮属性渲染
│   │   └── PreferencesWindowController.swift
│   ├── Core/                     # 纯逻辑层（5 个 .swift，仅 import Foundation，可测试）
│   │   ├── MarkdownParser.swift / ListMarkerDetector.swift / MarkdownTheme.swift
│   │   └── TextSearch.swift / DebugLog.swift
│   └── Supporting Files/
│       ├── Info.plist            # 文档类型注册 net.textility.markdown（.md/.markdown）
│       ├── PaperMD.entitlements  # 沙盒配置（3 键）
│       └── Main.storyboard       # 遗留资产：运行时菜单被 fixMenuStructure() 整体重建覆盖
├── PaperMDTests/                 # XCTest 单元测试（13 文件）
├── PaperMDUITests/               # XCUITest UI 测试（5 文件）
├── Tests/                        # 手工回归 fixture + 清单（SyntaxHighlightingTest.md / WritingSessionFixture.md / INPUT_REGRESSION_CHECKLIST.md）
├── Scripts/run-automated-tests.sh # 单元+UI 自动化测试脚本
├── .github/workflows/            # build-macos.yml / release-macos.yml / deploy-docs.yml
├── docs/                         # 编号文档体系（本 SOP 产物）+ 项目自有文档（ROADMAP/UI/TEXTKIT2_SPIKE/产品说明/VitePress 站点）
├── prototype/v0-old/、prototype/v1-new/  # 旧/新 HTML 原型（各 1 个 app-prototype.html）
├── README.md / CHANGELOG.md / CLAUDE.md
```

（来源：`docs/01_reverse/REVERSE_ANALYSIS.md` ②；目录现状经 2026-09-03 会话迁移后核对——design-system/ 与 docs/product|review|architecture 已并入编号目录）

## 3. 构建方式（Xcode 工程结构）

| 项 | 值 | 证据 |
|----|----|------|
| 工程文件 | `PaperMD.xcodeproj/project.pbxproj`（无 Package.swift / Package.resolved，非 SPM 工程） | 仓库 find 结果 |
| Targets | PaperMD（App，productName=PaperMD）、PaperMDTests、PaperMDUITests（bundle id com.papermd.app / com.papermd.app.tests / com.papermd.app.uitests） | project.pbxproj |
| 语言/版本 | Swift（SWIFT_VERSION = 5.0） | project.pbxproj |
| 最低部署 | MACOSX_DEPLOYMENT_TARGET = 14.0（6 处构建配置一致） | project.pbxproj；注意与 `README.md`「系统要求 macOS 12.0+」存在口径差，见 `TECH_STACK.md` §3 |
| Info.plist | `PaperMD/Supporting Files/Info.plist`（App target GENERATE_INFOPLIST_FILE=NO 显式指定；测试 target 为 YES 自动生成） | project.pbxproj、Info.plist |
| Entitlements | `PaperMD/Supporting Files/PaperMD.entitlements`（CODE_SIGN_ENTITLEMENTS 指定） | project.pbxproj |
| 版本号 | MARKETING_VERSION=1.0.0 / CURRENT_PROJECT_VERSION=1（Info.plist CFBundleShortVersionString=1.0） | project.pbxproj、Info.plist |
| 资源 | Main.storyboard 打包于 Resources（PBXBuildFile A100005）——运行时被程序化菜单覆盖的遗留资产 | project.pbxproj、REVERSE_ANALYSIS.md ①1.2 注意 |
| 构建命令链 | build-for-testing → 单元测试 → UI 测试（CI: GitHub Actions macos-14，xcodebuild） | `Scripts/run-automated-tests.sh`、`.github/workflows/build-macos.yml` |

## 4. 关键入口

| 入口 | 文件/位置 | 说明 |
|------|-----------|------|
| 进程入口 | `PaperMD/App/main.swift` | 显式创建 `AppDelegate()` 并赋给 `NSApplication.shared.delegate`，再 `NSApplicationMain`（注释注明 "required after removing Main.storyboard"） |
| 文档类注册 | `PaperMD/Supporting Files/Info.plist` | `NSDocumentClass = $(PRODUCT_MODULE_NAME).Document`；`NSDocumentControllerClass = PaperMDDocumentController`；CFBundleDocumentTypes 声明 .md/.markdown（Editor 角色） |
| 启动窗口保障 | `PaperMD/App/AppDelegate.swift` `ensureDocumentAndWindowVisible()` | 复用或新建 Document 并置前主窗口（800×600） |
| 菜单唯一来源 | `PaperMD/App/AppDelegate.swift` `fixMenuStructure()` | 程序化重建 7 大菜单（PaperMD/File/Edit/View/Format/Window/Help），覆盖 storyboard 菜单 |
| 文档读写 | `PaperMD/App/Document.swift` `read(from:)` / `data(ofType:)` / `writeSafely` | UTF-8 读写；保存前迁移 pending 图片资产 |
| 测试入口 | `Scripts/run-automated-tests.sh`；`Tests/INPUT_REGRESSION_CHECKLIST.md` | 自动化 + 手工 P0 回归双轨 |

## 5. 编号文档体系位置

本会话（2026-09-03）起，重构文档按《旧 App AI 重构 SOP v2.0》迁移至编号目录：`docs/00_context`～`docs/09_test` + `prototype/{v0-old,v1-new}`；索引见 `docs/DOCUMENT_INDEX.md`。项目自有文档（`docs/ROADMAP.md`、`docs/UI.md`、`docs/TEXTKIT2_SPIKE.md`、`docs/index.md`、`docs/产品说明.md`、`docs/.vitepress/`、`docs/package.json` 等）保持原位不动。
