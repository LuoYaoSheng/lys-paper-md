# PaperMD 数据与存储评审

> 评审依据：《AI 产品重构逻辑评审规范 v1.0》 · 2026-09-03
> 输入文档清单：
> 1. `docs/01_reverse/REVERSE_ANALYSIS.md`（⑦ 数据模型、事实源规则）
> 2. `docs/08_development/DATA_MODEL.md`（P7 重写数据模型）
> 3. `docs/02_product/PRD.md`（§5 功能列表 F006-F008/F014-F018/F049-F051）
> 4. `docs/06_review/PRODUCT_REVIEW.md`（P4 §四 公共能力 SV-01…SV-06，交叉引用）
> 5. 源码抽查：`PaperMD/App/Document.swift`、`ImageHandler.swift`、`PreferencesWindowController.swift`、`AppDelegate.swift`、`Supporting Files/PaperMD.entitlements`、`Supporting Files/Info.plist`
>
> 本文件为逻辑评审产出之一（DS- 编号问题清单），不修改任何现有文件。

---

## 一、数据清单逐项表

分类口径：按「数据分类（文档内容/草稿/偏好/会话/缓存/系统托管）× 存储位置与方式 × 应否保存 × 生命周期 × 结论」。

| # | 数据项 | 分类 | 存储位置与方式（证据） | 应否保存 | 生命周期（创建→消亡） | 结论 |
|---|--------|------|------------------------|:---:|------------------------|------|
| 1 | 文档正文（Markdown 源文本） | 文档内容 | 用户磁盘 `.md/.markdown`；`writeSafely`→`data(ofType:)`=`textView.string` UTF-8（`Document.swift` L129-137、L144-158） | 应存 ✔ | 输入起→每次保存/autosave 落盘；关闭随文件存续 | ✔ 合理（异常路径见 DS-07/DS-08） |
| 2 | 未保存文档正文（untitled） | 草稿 | **仅内存**（NSTextStorage）；autosave 明确 `guard fileURL != nil`（L194） | 应暂存 ✘ 未实现 | 输入起→首存或**进程终止即失** | ✘ **DS-06** |
| 3 | 图片资产（已保存文档） | 文档附属资源 | 文档同目录 `{文档名}.assets/image-{ts}-{hash}.png`（`ImageHandler.swift` L69-74、L76-80） | 应存 ✔ | 粘贴/拖入写盘→随文档目录存续；插入撤销可删（L218-226） | ✔ 合理；**创建可达性见 PM-02** |
| 4 | 图片资产（未保存文档 pending） | 临时数据 | `tmp/PaperMD-{UUID}.assets`（L140-149）；首存迁移后删目录（L61） | 临时 ✔ | 创建→首存迁移 / **文档不保存关闭→残留** | △ **DS-02**（不清理） |
| 5 | 图片撤销数据 | 内存（undo 栈） | `ImageInsertUndoHandler` 持 fileData 全量内存副本（L203-233） | 不落盘 ✔ | 插入→撤销栈释放 | ✔（大图多次插图内存放大，观察项，不入清单） |
| 6 | 偏好设置 | 用户偏好 | UserDefaults 3 键：`editorFontSize`/`appTheme`/`autosaveEnabled`（`PreferencesWindowController.swift` L239-269） | 应存 ✔ | 首次写入→跨启动存续；无重置入口（无删除键操作） | ✔ 合理（沙盒容器内自动隔离） |
| 7 | 最近文件列表 | 会话/导航数据 | 系统 `NSDocumentController.recentDocumentURLs` 托管（`AppDelegate.swift` L307-331） | 应存 ✔ | 系统管理；**沙盒下跨启动 URL 无访问授权** | ✘ **DS-04**（与 PM-01 同源） |
| 8 | 撤销栈 | 会话数据 | 窗口级 NSUndoManager，内存（`MarkdownTextView.swift` L59-65） | 不持久 ✔ | 窗口生命周期 | ✔ 符合预期 |
| 9 | 查找会话（词/替换/正则开关） | 会话数据 | 面板控件内存；**每次 ⌘F 重建即丢**（`AppDelegate.swift` L359-368） | 会话内应存 ✘ | 创建→面板重建即失 | ✘ **DS-05**（与 PL-06 同源） |
| 10 | 视图状态（侧栏/专注/窗口尺寸） | 会话数据 | 内存布尔 + 窗口对象；窗口恢复禁用（`Info.plist` NSDisableWindowRestoration；`Document.swift` L39-40 空实现） | 不存（产品决策）✔ | 窗口生命周期 | ✔ 自洽（观察项 DS-09） |
| 11 | 欢迎文本 | 常量 | 硬编码（`Document.swift` L83） | — | 新文档填充 | △ 与 DS-06/PL-01 叠加放大风险（P4 D6 交叉引用） |
| 12 | 语法高亮属性 | 派生数据 | NSTextStorage 属性，仅内存叠加（`CLAUDE.md` 事实源规则） | 不落盘 ✔ | 实时派生 | ✔ 严守「属性不入文件」不变量 |
| 13 | 导出产物（HTML） | 交付物 | 用户选择路径原子写（`ExportHelper.swift` L22-25） | 按需 ✔ | 导出即独立文件 | ✔（失败静默=P4 B5） |
| 14 | 日志 | 诊断数据 | DebugLog 仅 DEBUG 构建 NSLog（`Core/DebugLog.swift`） | 不持久 ✔ | 进程生命周期 | ✔（发布构建无日志，用户排障依赖可见反馈→B5 更重要） |

---

## 二、自动保存机制专项核对（§8）

当前设计（`Document.swift` L45、L179-206）：

1. 类属性 `autosavesInPlace=true`（L45）。
2. 实际调度为自定义 3 秒一次性 Timer：`updateChangeCount`/`read` 触发 `startAutosaveTimer`，条件 `fileURL != nil && Preferences.shared.autosaveEnabled`。
3. 到时回调再次 guard fileURL，且 `isDocumentEdited` 才执行 `autosave(withImplicitCancellability: false)`；失败 debugLog。

结论：

- **触发语义正确**（防抖 3 秒、仅脏文档、偏好可关）。
- **覆盖范围不完整**：untitled 无覆盖（DS-06）；解码失败伪文档被错误覆盖（DS-08）。
- **双机制并存疑点**：类属性恒 true 意味着 NSDocument 系统层（如 quit 时标准 autosave 触发点）可能与自定义 Timer 并行；偏好关闭自动保存时类属性不随之变化，系统层行为【未知】→ 归 ST-03/PM-04 立案。
- `stopAutosaveTimer()`（L208-211）无调用点（grep 证实）→ ST-04。

---

## 三、数据生命周期专项核对（§9）

| 生命周期问题 | 现状 | 结论 |
|--------------|------|------|
| 未保存变更（已保存文档） | 编辑→脏标→3 秒 autosave；Sudden Termination 下 <3s 窗口（UF-08/PL-04） | 基本 ✔ |
| 未保存变更（untitled 文档） | 无任何落盘 → 崩溃全丢 | ✘ DS-06 |
| 崩溃恢复 | 无 AutosaveInformation / 无恢复 UI；窗口恢复亦禁用 | ✘ 并入 DS-06 结论 |
| 临时文件清理（pending assets） | 仅首存迁移时清理；「不保存」关闭无钩子 | ✘ DS-02 |
| 迁移失败时的数据保全 | move 失败仍改写正文+删临时目录 | ✘ DS-01 |
| 外部修改（磁盘真相变化） | 无检测，autosave 覆盖 | ✘ DS-07 |
| 交付物生命周期 | 导出文件独立于文档状态（导出≠保存） | ✔ |
| 偏好生命周期 | UserDefaults 跨启动，无版本迁移（3 键均为原始类型，键名稳定） | ✔（低风险，不立案） |

---

## 四、问题清单（DS-01…）

### DS-01 首存图片迁移失败仍改写正文并无条件删除临时目录【B → PL-08】

- **当前设计**：`ImageHandler.migratePendingAssetsIfNeeded` L39-61：`try? moveItem`（L46）失败被吞后 `pathMap` 仍登记（L47）；正文按 pathMap 改写（L52-59）；`try? removeItem(at: pendingAssetsURL)` 无条件执行（L61）。
- **问题**：move 失败 → 引用指向不存在的目标 + 源文件随目录删除 → 图片数据与正文引用双失，不可撤销。
- **影响**：场景 4（粘贴图片）+ 首存的组合存在静默资产损失；违反「文件副作用成对可逆」的项目纪律。
- **建议方向**：事务式迁移（全部成功才改写+清理，任一失败中止保存并报错）；与 UF-05 同源同修。

### DS-02 tmp/PaperMD-{UUID}.assets 在「不保存关闭」后残留【D → PL-14】

- **当前设计**：pending 目录创建于 `resolveAssetsFolder`（L140-149）；唯一清理点是首存迁移（L61）与插入撤销（L218-226）。Document 关闭路径无清理钩子。
- **问题**：用户插图后选择「不保存」关闭 → 目录残留至系统 tmp 清理周期。
- **影响**：小（tmp 由 macOS 周期清理；仅占用磁盘），但生命周期不闭环。
- **建议方向**：观察不动；重写期可在 Document.close/deinit 时清理未迁移 pending 目录。

### DS-04 最近文件列表：系统托管但沙盒下跨启动不可达【B → PM-01/PL-02 同源】

- **当前设计**：`recentDocumentURLs` 系统存储；打开走 `openDocument(withContentsOf:)`，错误仅日志（`AppDelegate.swift` L333-340）；entitlements 无书签键，全源码无 security-scoped bookmark API。
- **问题**：沙盒的用户授权仅会话内有效，「最近文件」数据的**可用性**在重启后归零（数据在、打不开）。
- **影响**：数据分类上「应保存且已保存」但不可用，等同功能断链；详见权限分册 PM-01。
- **建议方向**：随 PM-01 处置（书签 entitlement + 解析失败可见反馈）。

### DS-05 查找会话数据随面板重建丢失【B → PL-06 同源】

- **当前设计**：查询词/替换词/正则开关仅存于面板控件；`showSearchReplace` 每次重建 controller（`AppDelegate.swift` L359-368）。
- **问题**：会话数据生命周期被错误地绑定到「面板窗口生命周期」而非「文档会话生命周期」。
- **影响**：重复检索成本；与 IA-02/UF-06 同源。
- **建议方向**：单例面板+FindSession（P7 DATA_MODEL.md §2.6 已有 V1 设计，方向一致）。

### DS-06 untitled 文档草稿无暂存、无崩溃恢复【B → PL-09 同源】

- **当前设计**：见 §二第 2 条；无 AutosaveInformation 使用。
- **问题/影响/建议方向**：与 UF-01 完全同源（流程视角）；数据视角结论：**「草稿」这一数据类别在当前设计中缺失**，与「自动保存」用户预期冲突。
- 归并处置，不重复展开。

### DS-07 文档磁盘真相与内存版本的一致性无保障【B → PL-05 同源】

- **当前设计**：无文件修改检测（grep 证实）；autosave/保存均直接覆盖。
- **问题**：以「内存为准」的单向同步，缺少磁盘侧变化的对账环节。
- **建议方向**：保存/autosave 前对账（修改时间或内容摘要），冲突给选择；与 UF-03 同源。

### DS-08 解码失败文件的「伪数据绑定」【B → PL-01 同源】

- **当前设计**：read 失败 rawText=""（`Document.swift` L167）→ 欢迎文本填充（L80-84）→ fileURL/autosave 照常绑定启动。
- **问题**：数据层面「文件内容=空/欢迎文本」与「fileURL=原文件」的组合是不一致状态（不变量「磁盘内容恒等于 textView.string 的 UTF-8」在打开时刻即被破坏）。
- **建议方向**：解码失败即解除 fileURL 绑定或转只读，与 UF-02/ST-01 同源同修。

### DS-09 重启后「回到现场」完全依赖用户手动重开【D → PL-16】

- **当前设计**：窗口恢复禁用（`Info.plist`）+ DS-04 的 Recent 不可达 → 重启后恢复工作状态的成本全部由用户承担（重新浏览定位文件）。
- **问题**：本地优先产品（文件即文档）下此取舍自洽，但与 DS-04 叠加后体验成本偏高。
- **影响**：低频场景（编辑器通常长驻）。
- **建议方向**：观察不动；若 PL-02 修复（Recent 可达），此项自然缓解。

---

## 五、结论

1. 数据**分类与归属基本正确**：该存的（文档/图片/偏好）有明确位置，不该持久的（撤销栈/高亮属性/查找会话）未越界落盘；无数据库、无私有格式，与「文件即文档」原则一致。
2. 短板集中在**生命周期的「异常半程」**：创建/主路径闭环，失败/放弃/崩溃的半程（DS-01/02/06/07/08）缺口密集——这与总报告 §17 第 5 项「不通过」结论对应。
3. 建议重写期将「数据不丢失不变量」显式化：任何时刻，用户已确认的内容要么在磁盘、要么有可恢复的暂存；当前设计未以此为约束。
