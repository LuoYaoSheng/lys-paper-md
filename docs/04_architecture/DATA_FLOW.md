# PaperMD 数据流动（DATA_FLOW）

> 版本：v1.0　日期：2026-09-03
> 事实来源：`docs/08_development/DATA_MODEL.md` §3（写路径数据流）；`docs/04_architecture/STATE_MACHINE.md` §1（状态分布总图）；`docs/01_reverse/REVERSE_ANALYSIS.md` ②（模块职责与关键机制）、⑦（事实源规则）；`PaperMD/App/Document.swift`、`ImageHandler.swift`、`EditorView.swift`（经上述文档转引的行号）
> 说明：本文档描述**旧 App 当前实现**的数据流动；重写期目标态见 `docs/04_architecture/SYSTEM_ARCH.md` §1 分层图。

---

## 1. 文本主数据流（文件 → Document → TextKit → 渲染）

```mermaid
flowchart LR
    subgraph IN[输入侧]
        K[键盘/粘贴/拖拽]
        F[(磁盘 .md UTF-8)]
    end
    subgraph CORE[内存处理]
        D[Document<br/>NSDocument 子类]
        TS[NSTextStorage.string<br/>唯一事实源]
        MF[MarkdownFormatter<br/>行级增量属性渲染]
        LM[NSLayoutManager<br/>TextKit 1 布局]
        OV[OutlineView<br/>parseHeadings 派生]
        SB[StatusBar<br/>DocumentStats 派生]
    end
    subgraph OUT[输出侧]
        W[(磁盘写入<br/>writeSafely UTF-8)]
        EH[HTML 导出<br/>MarkdownParser.exportToHTML]
    end
    F -->|read: String bytes UTF-8 解码| D
    D -->|rawText 载入| TS
    K --> TS
    TS -->|didProcessEditing<br/>.editedCharacters| MF
    MF -->|NSAttributedString 属性叠加<br/>不改源文本| LM
    TS --> OV
    TS --> SB
    TS -->|保存时同步 rawText| D
    D -->|textView.string 编码| W
    TS -->|派生解析| EH
```

（源：STATE_MACHINE.md §1「文本事实源=NSTextStorage.string，其余皆派生」+ REVERSE_ANALYSIS.md ②模块职责表 + ⑦事实源规则；DATA_MODEL.md §1 不变量「磁盘内容恒等于 textView.string 的 UTF-8 编码；格式化属性永不写入文件」）

**三条铁律级规则**（源：REVERSE_ANALYSIS.md ⑦，原始出处 `CLAUDE.md` + `Document.swift`）：

1. 保存文件 = `textView.string`（纯 Markdown，`![](path)` 为纯文本）。
2. 格式化只改 NSAttributedString 属性，永不改源文本语义。
3. IME（hasMarkedText()）期间跳过格式化重建。

## 2. 写路径数据流（编辑 → 落盘）

```mermaid
flowchart LR
    A[键盘/粘贴/拖拽] --> B[NSTextStorage]
    B --> C{IME marked?}
    C -- 是 --> D[仅统计刷新]
    C -- 否 --> E[行级增量高亮<br/>pendingEditedRange 合并]
    E --> F[大纲异步刷新]
    E --> G[统计刷新]
    B --> H[updateChangeCount]
    H --> I{自动保存开 且 fileURL?}
    I -- 是 --> J[3s Timer → autosave]
    I -- 否 --> K[等待 ⌘S]
    J --> L{失败?}
    L -- 是 --> M[仅 debugLog B5-2]
    L -- 否 --> N[(磁盘 UTF-8)]
```

（源：`docs/08_development/DATA_MODEL.md` §3 原图，原文件名 data-model.md）

## 3. 图片落地 assets 目录流（粘贴/拖拽 → 首存迁移）

```mermaid
flowchart TD
    A["⌘V / 拖入图片"] --> B{文档已保存过?<br/>documentURL 存在?}
    B -- 是 --> C["目标目录 {文档名去扩展}.assets/<br/>不存在则 createDirectory"]
    B -- 否 --> D["临时目录 tmp/PaperMD-{UUID}.assets<br/>textView.pendingAssetsURL 挂载"]
    C --> E["命名 image-{epochMillis}-{前8字节hash}.png<br/>data.write 落盘"]
    D --> E
    E --> F{写盘成功?}
    F -- 失败 --> G["不插入 仅 DebugLog（B5-3）"]
    F -- 成功 --> H["正文插入 ![](相对路径)<br/>注册 undo 组：文本+文件成对"]
    H --> I[继续编辑...]
    I --> J[⌘S 首次保存]
    J --> K["migratePendingAssetsIfNeeded:<br/>逐文件 move 至正式 assets 目录"]
    K --> L["构造 pathMap → 改写正文路径<br/>![](bare) → ![](相对)"]
    L --> M["⚠ 无条件删除整个临时目录<br/>（move 失败也删——UF-05 已知缺陷）"]
    M --> N[UTF-8 落盘 .md]
```

（源：REVERSE_ANALYSIS.md ⑥ 流程 3 + ② ImageHandler 行；目录约定与命名规则见 `DATA_MODEL.md` §2.4：`ImageHandler.swift` L12、L69-80、L131-155、L203-234；⚠ 事务性缺陷见 `docs/03_flow/BUSINESS_FLOW.md` §2.3）

**图片流的撤销语义**：文本删除与文件删除成对注册（ImageInsertUndoHandler），⌘Z 时 `![](path)` 文本消失且 assets 中文件同被删除，⌘⇧Z 双双恢复（源：`ImageHandler.swift` L203-234，经 PRD §8 F011-图片撤销条转引）。

## 4. 派生数据流（大纲/统计/导出，单向不回流）

| 派生物 | 输入 | 计算者 | 时机 | 回写? |
|--------|------|--------|------|:-----:|
| 大纲标题树 | NSTextStorage.string | MarkdownParser.parseHeadings（ATX1-6 空标题过滤 + Setext1/2，level 钳制 ≤6） | 文本变化后 DispatchQueue.main.async 异步 | 否 |
| 统计三元组 | NSTextStorage.string | StatusBar.DocumentStats（词=空白切分非空片段；字符=text.count；阅读=max(1,words/200)） | 每次文本变化（含 IME 期） | 否 |
| 导出 HTML | textView.string | MarkdownParser.exportToHTML（processInline 转义 + wrapHTML 主题 CSS） | ⌃⌘E 确认时一次性 | 否 |
| 语法高亮属性 | 受影响行文本 | MarkdownFormatter（行级 + 代码块前向扩展 ≤100 行） | didProcessEditing（非 IME、非重入） | 仅属性，不改字符 |

（源：REVERSE_ANALYSIS.md ② 模块职责表；STATE_MACHINE.md §1「单一事实源 + 派生只读……大纲、统计、导出 HTML 全部从 NSTextStorage 派生，绝不反向写回」）

## 5. 偏好数据流（三键 UserDefaults）

```mermaid
flowchart LR
    P[偏好窗口修改] --> U[UserDefaults 写入<br/>editorFontSize/appTheme/autosaveEnabled]
    U --> A[apply: 套 NSAppearance]
    A --> N[广播 .preferencesChanged]
    N --> E[EditorView 收到<br/>全文重排版（光标保存/恢复）]
    U -.启动时仅主题不广播.-> L[applyLaunchSettings]
```

（源：REVERSE_ANALYSIS.md ② 偏好行；`DATA_MODEL.md` §2.5；启动仅 applyLaunchSettings 避免就绪前重排版，`PreferencesWindowController.swift` L287-290）

## 6. 重写期数据流改造要点（承接既有决议，非本文新增）

- 分层规则：UI 不直接触文件系统；Parser/ListKit/Search 保持 Foundation-only；失败路径全部汇入 FeedbackCenter（B5）。（源：SYSTEM_ARCH.md §1）
- PersistenceStore.readUTF8 改 Result 化：解码失败返回 .decodeFailed 而非空串静默（B5-⑦，斩断 `BUSINESS_FLOW.md` §2.1 缺陷链的数据源）。（源：`docs/08_development/API_SPEC.md` §6）
- Replace All 禁止整串重置 `textView.string`，改 replaceCharacters + 撤销组（B3）。（源：API_SPEC.md §4）
