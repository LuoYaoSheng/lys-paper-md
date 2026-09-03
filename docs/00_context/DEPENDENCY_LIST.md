# PaperMD 依赖清单（DEPENDENCY_LIST）

> 版本：v1.0　日期：2026-09-03
> 核实方法：①全仓库 find `Package.swift` / `Package.resolved` / Podfile / Cartfile（排除 node_modules/.git）；②project.pbxproj 中 XCRemoteSwiftPackageReference / XCSwiftPackageProductDependency 段检查；③全源码 `import` 语句 grep 去重计数。
> 结论：**App 产物零第三方依赖**——仅系统框架。已核实，非推测。

---

## 1. 第三方依赖（App 构建产物）

| 类型 | 结果 | 核实证据 |
|------|------|----------|
| Swift Package Manager | **无**（无 Package.swift / Package.resolved；pbxproj 无 XCRemoteSwiftPackageReference / XCSwiftPackageProductDependency 依赖段） | find + pbxproj 审计 2026-09-03 |
| CocoaPods | **无**（无 Podfile / Podfile.lock / Pods/） | find 审计 |
| Carthage | **无**（无 Cartfile / Cartfile.resolved / Carthage/） | find 审计 |
| 手工 vendored 库（.framework/.a/.dylib） | **无**（pbxproj 47 个 PBXFileReference 中无二进制框架引用） | pbxproj 审计 |

> 逆向报告 ⑧ 结论一致：「无任何第三方 Swift 库（project.pbxproj 无 SPM/Carthage/Pod 依赖）」（`docs/01_reverse/REVERSE_ANALYSIS.md` ⑧）。

## 2. 系统框架依赖（App）

| 框架 | import 计数 | 用途 | 使用位置 |
|------|:-----------:|------|----------|
| Cocoa（AppKit+Foundation 伞） | 15 | 全部 UI：NSWindow/NSView/NSTextView/NSToolbar/NSMenu/NSSplitView/NSTableView/NSSavePanel/NSOpenPanel/NSPrintOperation… | `PaperMD/App/` 15 文件 |
| Foundation | 4 | 字符串/NSRegularExpression/Timer/UserDefaults/FileManager | `PaperMD/Core/` 5 文件中的 4 个 + `main.swift` |
| AppKit | 1 | 单独引入点 | import 审计（ExportHelper 相关文件群） |
| UniformTypeIdentifiers | 1 | UTType(.html/.plainText) | `AppDelegate.swift`、`Document.swift` |
| WebKit（WKWebView） | 1 | PDF 打印渲染（loadHTMLString 本地字符串） | `PaperMD/App/ExportHelper.swift` |

系统资源（非框架 import）：SF Symbols 工具栏 7 图标（见 `ASSET_INVENTORY.md` §1）。

## 3. 测试依赖

| 依赖 | 计数 | 说明 |
|------|:----:|------|
| XCTest | 18 | `PaperMDTests/`（13 文件）+ `PaperMDUITests/`（5 文件）——系统框架，无第三方断言/快照库 |

## 4. 构建/CI/文档工具链（不进 App 产物）

| 工具 | 版本/口径 | 用途 | 证据 |
|------|-----------|------|------|
| Xcode / xcodebuild | README 口径「Xcode 14.0+」；实际所需最低版本【未知——未在 CI 固定 xcode 版本前核实】 | 构建 + 测试 | `README.md` 92、`Scripts/run-automated-tests.sh` |
| GitHub Actions | runner macos-14 | build-macos（构建+测试）、release-macos（产出 PaperMD-macOS.zip，无公证）、deploy-docs | `.github/workflows/*.yml`（REVERSE_ANALYSIS.md ⑧） |
| VitePress | `^1.6.0`（devDependency，仅 docs 站点） | `docs/` 文档站与 GitHub Pages 部署 | `docs/package.json` |

> `docs/node_modules/` 为 VitePress 安装产物，属项目自有文档站资产，与 App 构建无关，本会话不触碰。

## 5. 零依赖的架构含义（承接既有结论）

- 稳定性：无供应链升级/漏洞面（`docs/04_architecture/SYSTEM_ARCH.md` §2 选型判定引「逆向报告 ⑧ 证实零第三方依赖的稳定性」）。
- 重写期约束：延续零第三方运行时依赖；测试框架 XCTest + XCUITest 保留全部 13+5 文件资产（SYSTEM_ARCH §2.2）。
