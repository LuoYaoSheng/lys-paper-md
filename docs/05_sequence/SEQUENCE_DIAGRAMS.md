# PaperMD 时序图集（SEQUENCE_DIAGRAMS）

> 版本：v1.0　日期：2026-09-03
> 事实来源：`docs/01_reverse/REVERSE_ANALYSIS.md` ②⑥⑨（模块职责/用户流程/未完成能力）；`docs/product-review/USER_FLOW_REVIEW.md`（UF-02/UF-03/UF-05/UF-07 源码还原）；`docs/06_review/PRODUCT_REVIEW.md` B5 清单；`PaperMD/App/{Document,AppDelegate,ImageHandler,ExportHelper,MarkdownTextView}.swift`（经上述文档转引的行号）
> 说明：共 5 张 sequenceDiagram，全部基于旧 App 现实现；已知缺陷在图内以注记标出（编号可回溯）。

---

## 图 1：打开文档（⌘O / Open Recent）

```mermaid
sequenceDiagram
    autonumber
    participant U as 用户
    participant AD as AppDelegate
    participant SYS as NSOpenPanel(系统)
    participant DC as PaperMDDocumentController
    participant DOC as Document
    participant EV as EditorView(TextKit)

    U->>AD: ⌘O
    AD->>SYS: runModal(.md/.markdown)
    SYS-->>U: 选择文件（沙盒授权点）
    SYS-->>DC: openDocument(withContentsOf:)
    DC->>DOC: read(from: fileURL)
    DOC->>DOC: String(data:encoding:.utf8) ?? ""
    Note over DOC: 解码失败不抛错→rawText=""（B5-7）<br/>⚠ 触发 UF-02 缺陷链（见图 4 注/ BUSINESS_FLOW §2.1）
    DOC->>EV: openEditorWindow 载入文本
    alt 编辑区为空（解码失败场景）
        DOC->>EV: 预填欢迎文本 # Hello PaperMD（L80-84）
    end
    EV->>EV: prepareForDisplay 重排版+大纲+统计+聚焦
    DOC->>DOC: startAutosaveTimer（fileURL≠nil 且偏好开，L174-176）
    EV-->>U: 窗口展示文档
```

（源：REVERSE_ANALYSIS.md ⑥ 流程 5；USER_FLOW_REVIEW.md §三）

## 图 2：自动保存（编辑静默 3 秒）

```mermaid
sequenceDiagram
    autonumber
    participant U as 用户
    participant TV as MarkdownTextView
    participant TS as NSTextStorage
    participant DOC as Document
    participant T as Timer(3s 一次性)
    participant FS as 磁盘

    U->>TV: 输入
    TV->>TS: 编辑字符
    TS-->>DOC: updateChangeCount(.changeDone)
    Note over DOC: guard fileURL != nil（L194）<br/>⚠ untitled 文档被排除（UF-01）
    DOC->>T: 重置 3 秒一次性 Timer（L188-206）
    U->>TV: 停止输入 ≥3 秒
    T->>DOC: fire → autosave(withImplicitCancellability:)
    DOC->>DOC: Task { @MainActor }（L197-203）
    DOC->>DOC: writeSafely（迁移 pending 图片 → data(ofType:)）
    DOC->>FS: textView.string UTF-8 原子写
    alt 写失败
        DOC->>DOC: 仅 debugLog（L201）⚠ B5-2 静默
    else 成功
        DOC-->>U: 标题栏脏标消除（无 toast）
    end
```

（源：USER_FLOW_REVIEW.md §二/§三；STATE_MACHINE.md §6 并发注记）

## 图 3：图片拖入 → 首存迁移（资产管线全链）

```mermaid
sequenceDiagram
    autonumber
    participant U as 用户
    participant TV as MarkdownTextView
    participant IH as ImageHandler
    participant TMP as tmp/PaperMD-{UUID}.assets
    participant DOC as Document
    participant AST as {文档名}.assets/
    participant FS as 磁盘(.md)

    U->>TV: 拖入图片（落点字符位置）
    TV->>IH: handleDroppedImage(at charIndex)
    IH->>IH: resolveAssetsFolder：documentURL 为 nil（未保存）
    IH->>TMP: createDirectory + data.write（image-{ms}-{hash8}.png）
    alt 写盘失败
        IH-->>TV: false → 不插入，仅 DebugLog（L126-128）⚠ B5-3
    else 成功
        IH->>TV: 插入 ![](bare 文件名) + 记录 pendingAssetsURL（L140-150）
        IH->>IH: 注册 undo 组（文本+文件成对，L203-234）
    end
    U->>DOC: ⌘S 首次保存
    DOC->>DOC: writeSafely → migratePendingAssetsIfNeeded（L144-158）
    IH->>TMP: 逐文件 try? moveItem → AST
    Note over IH,AST: ⚠ move 失败被吞但 pathMap 仍登记（L46-47）<br/>随后正文改写为新相对路径 → 无条件删整个 tmp 目录（L61）<br/>= UF-05 文本与文件双失缺陷
    IH->>TV: 正文改写 ![](bare)→![](相对)（L52-59）
    IH->>TMP: try? removeItem（整个目录）
    DOC->>FS: textView.string UTF-8 落盘
```

（源：REVERSE_ANALYSIS.md ⑥ 流程 3 + ② ImageHandler 行；USER_FLOW_REVIEW.md §四 UF-05）

## 图 4：导出 PDF（⌃⌘P 打印管线）

```mermaid
sequenceDiagram
    autonumber
    participant U as 用户
    participant AD as AppDelegate
    participant EH as ExportHelper
    participant MP as MarkdownParser
    participant WK as WKWebView(PrintableMarkdownView)
    participant PR as NSPrintOperation(系统)

    U->>AD: ⌃⌘P
    Note over AD: guard keyWindow.contentView is EditorView<br/>⚠ 非编辑窗口聚焦时静默 return（IA-01）
    AD->>EH: exportToPDF(currentDocument)
    EH->>MP: exportToHTML(markdown, theme)
    MP-->>EH: HTML（主题 CSS 内联）
    EH->>WK: PrintableMarkdownView(612×792) loadHTMLString(html, baseURL:nil)
    Note over WK: ⚠ 网络禁令 entitlements network.client=false：<br/>含 ![](http://…) 的远程图静默缺图（UF-07/PM-03）
    Note over EH,WK: ⚠ 异步加载完成与打印启动之间<br/>无等待时序【未知，大文档竞态未验证】（REVERSE ⑨）
    EH->>PR: NSPrintOperation.run()（横向 fit 纵向自动分页）
    PR-->>U: 系统打印面板
    U->>PR: 「存储为 PDF」
    PR-->>U: 系统完成 PDF 输出（写出位置由系统面板授权）
```

（源：REVERSE_ANALYSIS.md ⑥ 流程 4、⑧；USER_FLOW_REVIEW.md §六 UF-07；`ExportHelper.swift` L38-62）

## 图 5：外部修改冲突路径（现状=静默覆盖，已知缺陷 UF-03）

```mermaid
sequenceDiagram
    autonumber
    participant U as 用户
    participant EXT as 外部工具(Git/其他编辑器)
    participant DOC as PaperMD Document
    participant FS as 磁盘(.md)
    participant T as Timer(3s)

    Note over U,FS: 前置：PaperMD 已打开文件 A 且自动保存开启
    U->>DOC: 编辑文件 A（内存版本 v2）
    EXT->>FS: 修改文件 A → 磁盘版本 v3
    Note over DOC: ⚠ 全源码无 fileModificationDate/<br/>NSFileVersion/revertToSaved 检查<br/>（grep 零命中——UF-03 证据）
    U->>DOC: 停止输入 3 秒
    T->>DOC: autosave → writeSafely
    DOC->>FS: 用内存 v2 覆盖写（无提示）
    FS-->>EXT: v3 外部修改丢失
    Note over U,EXT: 用户全程无感知；重写期改为保存前比对磁盘<br/>修改时间/内容摘要 → 「保留我的版本/载入磁盘版本」选择
```

（源：USER_FLOW_REVIEW.md §三 UF-03 源码还原；该图为已知缺陷路径的时序化呈现，非推荐行为）

---

## 附：HTML 导出时序（补充，供对照图 4）

```mermaid
sequenceDiagram
    autonumber
    participant U as 用户
    participant AD as AppDelegate
    participant SYS as NSSavePanel(系统)
    participant EH as ExportHelper
    participant FS as 磁盘(.html)

    U->>AD: ⌃⌘E
    AD->>SYS: runModal（默认 {文档名}.html）
    SYS-->>U: 确认目标
    AD->>EH: convertToHTML + saveToURL
    EH->>FS: 原子写
    alt 写失败
        EH-->>AD: 仅 DebugLog（L397）⚠ B5-1 静默
    else 成功
        EH-->>AD: 仅 DebugLog（无用户提示）
    end
```

（源：REVERSE_ANALYSIS.md ⑥ 流程 4；`docs/06_review/PRODUCT_REVIEW.md` B5 第 1 点）
