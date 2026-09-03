# PaperMD 资产清单（ASSET_INVENTORY）

> 版本：v1.0　日期：2026-09-03
> 盘点方法：全仓库 `find`（排除 node_modules/.git）+ project.pbxproj 资源引用核对 + 源码常量提取。未发现项如实登记「无」，未证实处标【未知】。
> 结论先行：**本项目无资产目录（.xcassets）、无自有图标文件、无独立模板文件**——全部「资产」以源码常量、系统资源（SF Symbols）或文本 fixture 形式存在。

---

## 1. 资产目录与图标

| 资产 | 现状 | 证据 |
|------|------|------|
| Assets.xcassets / 任何 .xcassets | **不存在**（全仓库 find `*.xcassets` 零命中，排除 node_modules/.git） | find 审计 2026-09-03 |
| AppIcon | **无图标文件**；但 pbxproj 仍设 `ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon`、`ASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS = YES`——指向不存在目录的悬空配置，构建产出使用系统默认图标【构建警告行为未验证】 | `PaperMD.xcodeproj/project.pbxproj` L436/L499/L553/L584 |
| .icns / AppIcon* 文件 | 无（find 零命中） | find 审计 |
| UTType 图标 | `UTTypeIconFile` 为空字符串（文档类型注册无专属图标） | `PaperMD/Supporting Files/Info.plist` L44 |
| 工具栏图标 | **SF Symbols 系统资源**（7 项，无本地文件）：sidebar.left、bold、italic、chevron.left.forwardslash.chevron.right、textformat.size、text.quote、curlybraces | `PaperMD/App/WindowController.swift` L91-157 |

## 2. 文本模板（源码内嵌常量）

| 模板 | 内容 | 位置 |
|------|------|------|
| 欢迎文本文档 | `# Hello PaperMD\n\nStart typing your Markdown here...`（新建空文档预填） | `PaperMD/App/Document.swift` L83（F053，来源 `docs/02_product/PRD.md` §5） |
| 图片文件命名规则 | `image-{epochMillis}-{data 前 8 字节大整数}.png` | `PaperMD/App/ImageHandler.swift` L76-80 |
| 图片资产目录约定 | 已保存：`{文档名}.assets/`；未保存：`tmp/PaperMD-{UUID}.assets`；兜底：`tmp/PaperMD.assets` | `PaperMD/App/ImageHandler.swift` L12、L131-155 |
| 主题色板（双端） | 编辑器 11 语义色（heading/code/link/image/listMarker/quote/meta/hr/htmlTag/task/imageLineBackground）× 明暗 + 导出 CSS（light/dark，system 跟随 NSApp.effectiveAppearance） | `PaperMD/Core/MarkdownTheme.swift` L8-66 |
| 偏好默认值 | editorFontSize=16（档位 12-24 十档）/ appTheme=system / autosaveEnabled=true | `PaperMD/App/PreferencesWindowController.swift` L271-280 |
| 窗口尺寸常量 | 主窗口 800×600 / 偏好窗 450×300 / 查找面板 420×160 | `Document.swift` L63、`PreferencesWindowController.swift` L16、`SearchReplaceController.swift` L19（`docs/07_design_system/TOKEN.md` §3 单一来源登记） |

## 3. 文档与原型资产（本 SOP 体系）

| 资产 | 位置 | 说明 |
|------|------|------|
| v0 旧版 HTML 原型 | `prototype/v0-old/app-prototype.html` | 旧 App 全量页面原型（1 文件） |
| v1 新版 HTML 原型 | `prototype/v1-new/app-prototype.html` | B1-B8 修复后规格原型（1 文件） |
| 编号文档体系 | `docs/00_context`～`docs/09_test` | 索引见 `docs/DOCUMENT_INDEX.md` |
| 产品逻辑评审六件套 | `docs/product-review/`（原位不动） | DATA_STORAGE / INFORMATION_ARCHITECTURE / PERMISSION / PRODUCT_LOGIC / STATE / USER_FLOW 六分册 |

## 4. 测试 fixture 资产

| 资产 | 内容 | 来源 |
|------|------|------|
| `Tests/SyntaxHighlightingTest.md` | 高亮全覆盖样板（147 行：ATX/Setext 标题、粗斜删、行内码、链接图片、三类列表、代码块 swift/js/~~~、嵌套引用、HR、HTML 标签、组合） | `docs/01_reverse/REVERSE_ANALYSIS.md` 附 |
| `Tests/WritingSessionFixture.md` | 长时写作中文混排样板 | 同上 |
| `Tests/INPUT_REGRESSION_CHECKLIST.md` | P0 输入/光标/源保真 14 项 + P1 功能 5 项 + 长时写作 1 项 | 同上 |
| `PaperMDTests/TestFixtures.swift` | 单元测试共享 fixture | `PaperMDTests/` |

## 5. 项目自有文档资产（不属本 SOP，登记备查）

`README.md`、`CHANGELOG.md`、`CLAUDE.md`、`docs/ROADMAP.md`、`docs/UI.md`、`docs/TEXTKIT2_SPIKE.md`、`docs/index.md`、`docs/产品说明.md`、VitePress 站点（`docs/.vitepress/`、`docs/package.json`、`docs/public/`、`docs/node_modules/`）。均保持原位，本会话未触碰。

## 6. 缺口与风险登记

1. **无应用图标**：悬空的 ASSETCATALOG_COMPILER_APPICON_NAME 配置指向不存在的 AppIcon——重写期需补图标资产或清理配置（属工程决策，留档）。
2. **无 onboarding/帮助资产**：Help 菜单无 .help bundle（`AppDelegate.swift` showHelp，行为【未知】，P4 C2 留档）。
3. 欢迎文本随首存写入文件（D6，产品决策照旧）——见 `docs/06_review/PRODUCT_REVIEW.md` L-06。
