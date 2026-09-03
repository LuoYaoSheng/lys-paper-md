# PaperMD 技术栈（TECH_STACK）

> 版本：v1.0　日期：2026-09-03
> 事实来源：`PaperMD.xcodeproj/project.pbxproj`（逐项 grep）、全源码 import 审计、`docs/01_reverse/REVERSE_ANALYSIS.md` ①1.2 与 ⑧、`README.md`「技术栈/系统要求」、`CLAUDE.md`
> 说明：仓库无 `Package.swift` / `Package.resolved` / Podfile / Cartfile——SPM/CocoaPods/Carthage 零第三方包依赖（见 `DEPENDENCY_LIST.md`）。版本事实以 project.pbxproj 为准。

---

## 1. 语言与框架版本

| 项 | 事实值 | 证据 |
|----|--------|------|
| 语言 | Swift | 全部源码 `.swift`（App 15 文件 + Core 5 文件 + 测试 18 文件，pbxproj 文件引用清单） |
| Swift 版本设置 | SWIFT_VERSION = 5.0 | `PaperMD.xcodeproj/project.pbxproj` |
| UI 框架 | AppKit（编辑器 100% AppKit，**无 SwiftUI**） | `PaperMD/App/*.swift` 全部 `import Cocoa`；`CLAUDE.md` "no SwiftUI in editor" |
| 文档架构 | NSDocument / Document-based App | `PaperMD/App/Document.swift`、`PaperMDDocumentController.swift`、`Info.plist` CFBundleDocumentTypes |
| 编辑引擎 | **TextKit 1**：NSTextView + NSLayoutManager + NSTextStorage 手工管线 | `PaperMD/App/EditorView.swift` L52-70（来源：REVERSE_ANALYSIS.md ①1.2）；TextKit 2 仅 v1.2 Spike 计划（`docs/TEXTKIT2_SPIKE.md`，状态 Planned） |
| 最低部署目标 | MACOSX_DEPLOYMENT_TARGET = 14.0（6 处构建配置一致） | `PaperMD.xcodeproj/project.pbxproj` |
| 最低系统声明 | Info.plist `LSMinimumSystemVersion = $(MACOSX_DEPLOYMENT_TARGET)`；README 写「macOS 12.0 或更高版本，Xcode 14.0+」 | `PaperMD/Supporting Files/Info.plist` L21-22、`README.md` 89-92 |
| 应用版本 | CFBundleShortVersionString=1.0（pbxproj MARKETING_VERSION=1.0.0 / CURRENT_PROJECT_VERSION=1） | `Info.plist`、project.pbxproj |
| 沙盒 | App Sandbox 开启 + 用户选择文件读写；网络客户端显式关闭 | `PaperMD/Supporting Files/PaperMD.entitlements` |

### 最低系统口径差（登记，不裁定）

`README.md` 声称 macOS 12.0+，而当前工作区 `project.pbxproj` 全部 6 处 MACOSX_DEPLOYMENT_TARGET 为 **14.0**。逆向报告（写于 README 口径）记 12.0+。两处事实并存，以 pbxproj 为构建事实；差异原因【未知——可能与未提交的工作区改动有关，该项目存在历史未提交改动，本会话不触碰】。相关讨论：`docs/04_architecture/SYSTEM_ARCH.md` §2.2 曾按「旧版 12.0」讨论 D2（Preferences/Settings 措辞）。

## 2. 系统能力（框架 import 审计，2026-09-03 全源码 grep）

| 框架 | import 计数（App+Core / Tests） | 用途 | 证据 |
|------|------|------|------|
| Cocoa（含 AppKit/Foundation） | 15 / — | 全部 UI（NSWindow/NSTextView/NSToolbar/NSMenu/NSSplitView/NSTableView/NSSavePanel…） | `PaperMD/App/` 15 文件 |
| Foundation | 4 / 1 | 字符串/正则（NSRegularExpression）/Timer/UserDefaults/FileManager | `PaperMD/Core/` 全部 + `main.swift` 等；Core 层仅 Foundation（可测试性设计） |
| AppKit（单独） | 1 | ExportHelper 之外的单点使用 | import 审计 |
| UniformTypeIdentifiers | 1 | UTType(.html/.plainText) | `AppDelegate.swift`、`Document.swift`（REVERSE_ANALYSIS.md ⑧） |
| WebKit（WKWebView） | 1 | PDF 打印渲染视图（loadHTMLString → NSPrintOperation） | `PaperMD/App/ExportHelper.swift` |
| XCTest / XCUITest | — / 18 | 13 单元测试文件 + 5 UI 测试文件 | `PaperMDTests/`、`PaperMDUITests/` |

补充系统能力（非 import，运行时使用）：

- NSPrintOperation/NSPrintInfo：PDF 输出管线（`ExportHelper.swift`）。
- SF Symbols：工具栏 7 图标经 `NSImage(systemSymbolName:)` 引用（`WindowController.swift` L91-157：sidebar.left / bold / italic / chevron.left.forwardslash.chevron.right / textformat.size / text.quote / curlybraces）。
- NSUndoManager：窗口级撤销（`MarkdownTextView.swift` L59-65、`Document.swift`）。
- NSDocument 自动保存体系：`autosavesInPlace=true` + 自定义 3 秒 Timer（`Document.swift` L45、L188-206）。
- 网络能力：**关闭**（entitlements `com.apple.security.network.client=false`）——WKWebView 仅加载本地 HTML 字符串，远程图片不可达（`docs/product-review/PERMISSION_REVIEW.md` PM-03）。

## 3. 渲染与文本管线要点（TextKit 1 事实）

| 能力 | 现状 | 证据 |
|------|------|------|
| 布局管线 | NSTextStorage + NSLayoutManager + NSTextContainer 手工搭建 | `EditorView.swift` L52-70 |
| 高亮方式 | 属性叠加（NSAttributedString 属性），永不改源文本 | `CLAUDE.md` 事实源规则、`MarkdownFormatter.swift` |
| 行级增量 | 仅重算受影响行 + 代码块范围扩展（向前 ≤100 行） | `MarkdownFormatter.swift` L175、REVERSE_ANALYSIS.md ② |
| IME 保护 | `hasMarkedText()` 期间跳过格式化重建 | `EditorView.swift`、`CLAUDE.md` P0 规则 3 |
| 光标保持 | 格式化前后选区保存/恢复 | `EditorView.swift` L267-302（REVERSE_ANALYSIS.md ②） |
| TextKit 2 迁移 | 未实现；v1.2 Spike 计划（门槛：2 周、10k 行基准、IME+undo 全量回归、零 P0 回归才迁） | `docs/TEXTKIT2_SPIKE.md`、`docs/04_architecture/SYSTEM_ARCH.md` §3 |

## 4. 工具链

| 工具 | 用途 | 证据 |
|------|------|------|
| Xcode / xcodebuild | 构建（project + scheme PaperMD） | `PaperMD.xcodeproj`、`Scripts/run-automated-tests.sh` |
| GitHub Actions（macos-14 runner） | build-macos（构建+测试）、release-macos（产出无公证 zip）、deploy-docs | `.github/workflows/*.yml` |
| VitePress（npm devDependency） | docs/ 文档站与 GitHub Pages 部署（仅文档，不进 App 产物） | `docs/package.json` |
