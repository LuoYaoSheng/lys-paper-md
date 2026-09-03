# PaperMD 重写内部模块契约（P7 · api-design）

> 版本：v1.0　日期：2026-09-02
> 说明：PaperMD 无 HTTP/网络（沙盒网络关闭）。本文件定义**进程内模块契约**（Swift protocol 层），作为重写的编码起点与测试桩依据。签名尽量沿用可迁移的旧实现；V1 行为变化标注 B 类。
> 命名空间建议：`PaperMDCore`（Foundation-only）与 `PaperMDApp`（AppKit）。

---

## 1. EditorEngine（编辑引擎——P0 铁律所有者）

```swift
/// 编辑引擎：TextKit 管线 + IME 保护 + 光标保持 + 格式化命令统一入口
/// （归位旧 EditorView/Document/MenuActions 三处重复实现——P4 D1）
protocol EditorEngineDelegate: AnyObject {
    func engineTextDidChange(_ engine: EditorEngine)          // 已完成调度（非 IME）
    func engineStatsOnlyUpdate(_ engine: EditorEngine)        // IME 组合期（仅统计）
}

protocol EditorEngine: AnyObject {
    var textView: MarkdownTextView { get }                    // 暴露给 Document/面板的唯一样本
    var delegate: EditorEngineDelegate? { get set }

    // MARK: 调度（承接 EditorView L281-323）
    func scheduleFormatting(editedRange: NSRange)             // 0 延迟 coalesce + pendingEditedRange 合并
    func reapplyAllFormatting()                               // 全量（偏好变化/主题切换），选区保存恢复
    var isApplyingFormatting: Bool { get }                    // 防重入（只读暴露）

    // MARK: 格式化命令（F032-F039 · B1 扩至 H1-H6）
    func applyInline(_ kind: InlineKind)                      // bold/italic/code/strikethrough（需选区，返回 false 表示无选区→菜单禁用）
    func applyHeading(level: Int)                             // 1-6（B1）；行首替换+剥离旧 #
    func applyBlockquote()
    func applyCodeBlock()
    func insertLink()

    // MARK: 选区
    var selectedRange: NSRange { get }
    func scrollRangeToVisible(_ range: NSRange)
    func jumpToLine(_ lineNumber: Int)                        // 大纲跳转（UTF-16 一致计数——C6 修复点）

    enum InlineKind { case bold, italic, code, strikethrough }
}
```

契约要点：

1. `applyInline` 无选区时返回不可用状态（供 validateUserInterfaceItem/F058）。
2. 所有命令内部保证：注册撤销组 + 光标语义（包裹后整段选中/行首命令光标在前缀后——page-spec PAGE004）。
3. `jumpToLine` 偏移计算**统一使用 NSString UTF-16 计数**（修复旧 `charIndex < text.count` Character 混用——C6）。

## 2. MarkdownHighlighter（高亮引擎）

```swift
/// 行级增量属性渲染（承接 MarkdownFormatter，静态类改实例以注入主题）
protocol MarkdownHighlighter: AnyObject {
    func setBaseFontSize(_ size: Int)                         // 档位 12-24
    func setTheme(_ style: MarkdownThemeStyle)
    /// 仅重算受影响行；内部扩展代码块范围（前向 ≤100 行，上限属 C3 决策）
    func applyFormatting(to storage: NSTextStorage, editedRange: NSRange)

    // V1 新增（B4）：表格行/分隔行着色分支（消费 MarkdownBlockKind.tableRow/.tableSeparator）
    // 行为：tableRow → syntax-table 色 + 行内格式照常；tableSeparator → meta 弱化
}
```

## 3. MarkdownParser（解析核心，Foundation-only 保持可测试）

```swift
enum MarkdownParser {
    static func parseLines(_ text: String) -> [MarkdownLine]          // 14 块类型（data-model §2.2）
    static func parseHeadings(from text: String) -> [MarkdownHeading] // ATX1-6（空标题过滤）+Setext1/2，level 钳制 ≤6
    static func exportToHTML(_ markdown: String, theme: MarkdownThemeStyle) -> String
    // 块判定辅助（保持既有可见性供测试）：atxHeadingLevel/atxHeadingText/isHorizontalRule/
    // isTableRow/isTableSeparator/isStandaloneImageLine
}
```

## 4. SearchService（查找替换——B2/B3/B6 行为升级）

```swift
enum SearchError: Error { case invalidRegex(pattern: String) }        // V1：不再静默（B5-④）

struct FindSession {                                                  // data-model §2.6
    var query: String
    var replacement: String
    var useRegex: Bool
    var matchTotal: Int                                               // B6 计数
    var currentOrdinal: Int
    var wrapped: Bool                                                 // B6 回绕提示
}

protocol SearchService {
    /// 返回 nil=无命中；throws=正则非法（调用方走 FeedbackCenter）
    func rangeOfNextMatch(session: FindSession, in text: NSString, from utf16Index: Int) throws -> NSRange?
    func rangeOfPreviousMatch(session: FindSession, in text: NSString, from utf16Index: Int) throws -> NSRange?   // B2：⇧⌘G
    /// B3：单处替换——经 EditorEngine 注册撤销组后执行
    func replaceOne(session: FindSession, in textView: NSTextView) throws -> Bool
    /// B3：全部替换——必须以 undo 分组 + replaceCharacters 实现（禁止整串重置），
    /// 保持选区/视口；返回替换计数供面板状态行
    func replaceAll(session: FindSession, in engine: EditorEngine) throws -> Int
}
```

## 5. AssetService（图片资产管线）

```swift
protocol AssetService {
    /// ⌘V / 拖拽入口：识别剪贴板/拖拽图片 → 落盘 → 插入 ![](相对路径) → 注册文件级撤销组
    /// 返回 false = 非图片（调用方回落纯文本粘贴路径）
    func handlePastedImage(in textView: MarkdownTextView, documentURL: URL?) -> Bool
    func handleDroppedImage(in textView: MarkdownTextView, at charIndex: Int, image: NSImage, documentURL: URL?) -> Bool

    // 目录与命名（data-model §2.4）
    static func assetsFolderURL(for documentURL: URL) -> URL          // {文档名}.assets/
    static func generateFilename(for data: Data) -> String            // image-{ms}-{hash8}.png
    static func relativeAssetsPath(filename: String, documentURL: URL) -> String

    /// 首存迁移：pending tmp 目录 → 正式 assets；改写正文路径；成对删除临时目录
    @discardableResult
    func migratePendingAssetsIfNeeded(textView: MarkdownTextView, pendingAssetsURL: URL, documentURL: URL) -> Bool

    // V1（B5）：落盘失败由调用方 FeedbackCenter 呈现（旧版仅 DebugLog）
}
```

## 6. PersistenceStore / ExportService

```swift
protocol PersistenceStore {
    func readUTF8(from data: Data) -> Result<String, DecodeError>    // V1：失败返回 .decodeFailed（B5-⑦）而非空串静默
    func writeAtomically(_ string: String, to url: URL) throws       // UTF-8；writeSafely 语义
}

enum ExportTheme { case light, dark }                                 // 由 PreferencesStore.theme 解析（含 system 跟随）

protocol ExportService {
    func convertToHTML(markdown: String, theme: ExportTheme) -> String
    func saveToURL(_ content: String, url: URL) throws                // 原子写；失败→FeedbackCenter（B5-①）
    /// PDF：HTML → WKWebView(612×792) 渲染完成回调后才允许 NSPrintOperation run（时序显式化；旧版未等待【未知】）
    func printPDF(markdown: String, theme: ExportTheme, window: NSWindow, onRendered: @escaping () -> Void)
}
```

## 7. PreferencesStore / FeedbackCenter / ListMarkerKit

```swift
protocol PreferencesStore {
    var fontSize: Int { get set }                                     // editorFontSize，默认 16
    var theme: Theme { get set }                                      // appTheme，默认 system
    var autosaveEnabled: Bool { get set }                             // 默认 true
    func apply()                                                      // 套 NSAppearance + 广播 preferencesChanged
    func applyLaunchSettings()                                        // 启动仅主题（不广播）
}

enum FeedbackEvent {                                                  // V1 新增（B5/B6 载体，CP-11）
    case toast(String)                                                // 自动保存成功/失败、图片失败
    case alert(title: String, message: String, detail: String?)       // 导出失败/解码失败/最近文档失效
    case findStatus(FindSession, SearchError?)                        // 面板状态行
}
protocol FeedbackCenter { func emit(_ event: FeedbackEvent) }

enum ListMarkerKit {                                                  // A2 修复：空内容也识别
    /// 识别行首列表 marker（"- "/"1. "/"- [ ] " 均允许内容为空——修复旧版空项分支不可达）
    static func marker(for line: String) -> String?
    static func isListItem(_ line: String) -> Bool
    static func nextOrderedMarker(after marker: String) -> String?    // n. → (n+1).
}
```

## 8. 菜单配置契约（C4 可决策化）

```swift
struct MenuSpec {                                                     // 归位 AppDelegate.fixMenuStructure（CF-05）
    struct Item {
        var title: String
        var action: Selector?
        var keyEquivalent: String?
        var modifiers: NSEvent.ModifierFlags?
        var conflictNote: String?                                     // C4：⌥⌘C 双义等在此登记，运行时可标注
    }
    static func build() -> [NSMenu]                                   // 7 菜单全量（patterns.md §4.1 为唯一参数表）
}
```

## 9. 契约测试要求（承接 PaperMDTests 资产）

| 模块 | 必测用例（旧资产迁移 + 新增） |
|------|------------------------------|
| MarkdownParser | MarkdownParserTests/MarkdownExportParityTests 全量保留；**新增** tableSeparator 边界 |
| ListMarkerKit | ListMarkerDetectorTests + **新增空项识别**（A2 回归：`"- "` 须命中、Enter 删 marker） |
| SearchService | TextSearchTests + **新增** replaceAll 撤销组/选区保持（B3）、invalidRegex 抛出（B5） |
| AssetService | ImageHandlerTests 4 用例 + DocumentPersistenceTests 迁移用例保留 |
| EditorEngine | EditorInteractionTests（IME/光标）+ **新增** jumpToLine UTF-16 一致性（C6） |
| Highlighter | MarkdownFormatterFixtureTests + **新增** tableRow/tableSeparator 着色（B4） |
