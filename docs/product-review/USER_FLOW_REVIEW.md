# PaperMD 用户流程评审

> 评审依据：《AI 产品重构逻辑评审规范 v1.0》 · 2026-09-03
> 输入文档清单：
> 1. `docs/01_reverse/REVERSE_ANALYSIS.md`（⑥ 用户流程 Mermaid 1-6）
> 2. `docs/02_product/PRD.md`（§3 使用场景、§7 业务流程）
> 3. `docs/02_product/PAGE_SPEC.md`（三、六项特检矩阵）
> 4. `docs/06_review/PRODUCT_REVIEW.md`（P4 §三 流程问题 L-01…L-07，交叉引用）
> 5. 源码抽查：`PaperMD/App/Document.swift`、`AppDelegate.swift`、`ImageHandler.swift`、`ExportHelper.swift`、`SearchReplaceController.swift`、`MarkdownTextView.swift`、`Supporting Files/Info.plist`
>
> 本文件为逻辑评审产出之一（UF- 编号问题清单），不修改任何现有文件。

---

## 一、流程走查方法

五要素 = 触发 / 前置条件 / 主路径 / 结果反馈 / 异常分支。每条核心流程先画「理论最快路径」，再对照源码还原「现路径」，逐要素打勾，异常分支单列。所有源码行号以当前工作区文件为准。

---

## 二、流程 1：新建 → 写作 → 保存

**理论最快路径**：双击 App → 立即可打字 → ⌘S（首存弹面板选目录）→ 完成。

**现路径还原**（`AppDelegate.swift` L27-87 → `Document.swift` L54-94 → L129-158）：

1. 启动 → `ensureDocumentAndWindowVisible()` → 无 Document 则新建 → `openEditorWindow()` → 预填欢迎文本（L80-84）→ 聚焦。
2. 输入 → `updateChangeCount(.changeDone)` → 标题栏脏标（`EditorView.swift` L219）。
3. ⌘S → 无 fileURL 弹 NSSavePanel（默认 untitled.md，L213-238）→ `writeSafely` → 迁移 pending 图片（L144-158）→ `data(ofType:)` 取 `textView.string` UTF-8 落盘（L129-137）。

**五要素**：触发 ✔；前置 ✔；主路径 ✔ 最短；结果反馈 ✔（脏标消除）；异常分支 ✘（见 UF-01）。

### UF-01 未保存（untitled）文档无自动保存、无崩溃恢复，最长丢失窗口=整个写作会话【B → PL-09】

- **当前设计**：自动保存计时器回调 `guard let self, self.fileURL != nil`（`Document.swift` L194），untitled 文档被明确排除；未使用 NSDocument 标准的 AutosaveInformation 隐式保存目录（全源码无此机制）。同时 Info.plist 声明 `NSSupportsSuddenTermination=true`（UF-08 关联）。
- **问题**：场景 2「连续写作 1 小时」（PRD.md §3）若发生在未首存的文档上，崩溃/强退=全丢。PRD 将 F008 描述为「自动保存：偏好开关，3 秒无操作落盘」，未限定「仅已保存文档」出现在页面级文档（page-spec PAGE010 提到计时启动条件），用户无从知晓该边界。
- **影响**：与「自动保存」的用户预期直接冲突；新用户最可能处于 untitled 状态（场景 1 快速开写），恰是最脆弱的时段。
- **建议方向**：重写期将 untitled 文档纳入标准 NSDocument 自动保存体系（落 AutosaveInformation，重启可恢复）；若维持现状，须在产品文档与 UI 内明示「保存前内容不自动落盘」。

### 交叉引用

- 欢迎文本随首存入文件：P4 L-06/D6（维持观察）。
- 首存迁移图片：见流程 3 / UF-05。

---

## 三、流程 2：打开已有文件 → 编辑 → 自动保存

**理论最快路径**：⌘O（或 Open Recent）→ 选文件 → 编辑 → 3 秒静默落盘 → 关闭无忧。

**现路径还原**（`AppDelegate.swift` L124、L333-340 → `Document.swift` L166-206）：

1. ⌘O 系统面板 / Recent 项 → `Document.read(from:)`：`String(data: data, encoding: .utf8) ?? ""`（L167）→ 载入 → `startAutosaveTimer()`（L174-176，条件：fileURL≠nil 且偏好开）。
2. 编辑 → `updateChangeCount` → 重置 3 秒一次性 Timer（L188-206）→ 到时 `autosave(withImplicitCancellability:)`，失败仅 debugLog（L201）。

**五要素**：触发 ✔；前置 ✘（Recent 跨启动不可达，PM-01/PL-02，归权限分册）；主路径 ✔；结果反馈 ✘（静默落盘可接受，但失败静默=P4 B5 第 2 点）；异常分支 ✘✘（UF-02、UF-03）。

### UF-02 非 UTF-8 文件解码失败 → 「欢迎文本文档」绑原路径 → 3 秒自动保存覆盖写回【B → PL-01，升级 P4 L-03/B5】

- **当前设计**：`read(from:)` 解码失败 `rawText=""`（`Document.swift` L167），**不抛错**；随后 `openEditorWindow()` 走 `else if editorView.textView.string.isEmpty` 分支填入欢迎文本 `# Hello PaperMD…`（L80-84）；此时 displayName=原文件名、fileURL 已绑定、自动保存计时器已启动（read L174-176）。
- **问题**：P4 L-03 记录的是「静默打开空文档」；实际行为更重——窗口展示的是欢迎模板而非空文档，用户更难意识到内容非原文件；首次输入触发 changeCount → 3 秒后 `writeSafely` 用「欢迎文本+输入」覆盖原文件（GBK 等非 UTF-8 编码的中文 .md 是核心用户群的真实文件形态，见 PRD.md §2 中文用户画像）。
- **影响**：全部静默失败路径中后果最重的一条，构成「打开 → 看似正常 → 编辑 → 原文件被毁」的完整数据损失链。
- **建议方向**：重写期将「解码失败」改为可见错误并**不绑定 fileURL 进入可保存状态**（或以只读+提示打开）；编码失败时禁止自动保存计时（P4 B5 的 L-03 处置需按此升级）。

### UF-03 文件被外部修改无检测，自动保存静默覆盖【B → PL-05】

- **当前设计**：全源码无文件修改日期/NSFileVersion/呈现冲突检查（grep `NSFileVersion|fileModificationDate|revertToSaved` 无命中）；自定义 Timer 直接调 `autosave` 覆盖写。
- **问题**：开发者用户（PRD.md §2 首位画像）常在 Git/其他编辑器侧改同一文件；PaperMD 侧 3 秒 autosave 会无提示地用内存版本覆盖磁盘上的外部修改。
- **影响**：多工具写作场景下的外部工作丢失；因 autosave 默认开启，用户甚至不知道覆盖何时发生。
- **建议方向**：重写期保存前比较磁盘修改时间/内容摘要，不一致时给「保留我的版本/载入磁盘版本」选择；这是 macOS 文档应用（NSDocument 标准链路）的常规兜底。

### 交叉引用

- 打开失败仅日志（Recent）：P4 B5 第 6 点 + PL-02（沙盒根因）。
- 大文档加载无 loading：page-spec 特检矩阵已如实标注（✔/⚠ 呈现策略），维持 V1 原型处置。

---

## 四、流程 3：插入图片 → 首次保存迁移

**理论最快路径**：⌘V → `![](相对路径)` 落盘 → ⌘S 首存 → 图片自动迁至 `{文档名}.assets/`。

**现路径还原**（`MarkdownTextView.swift` L102-122 → `ImageHandler.swift` L114-155、L26-67）：

1. ⌘V → `handlePastedImage` → `saveAndInsertImage`：写盘失败仅 debugLog 不插入（L126-128，P4 B5 第 3 点）；未保存文档写入 `tmp/PaperMD-{UUID}.assets` 并记 `pendingAssetsURL`（L140-150）。
2. ⌘S → `writeSafely` → `migratePendingAssetsIfNeeded`（`Document.swift` L144-158）：逐文件 `try? moveItem`（L46）→ 无条件构造 pathMap → 改写正文 → **无条件删除整个临时目录**（L61）。

**五要素**：触发 ✔；前置 ✘（已保存文档在沙盒下创建同级 `.assets/` 的可达性【未知】→ PM-02/PL-03）；主路径 ✔；结果反馈 ✘；异常分支 ✘（UF-05）。

### UF-05 首存迁移失败仍改写正文并无条件删除临时目录 → 图片数据丢失【B → PL-08】

- **当前设计**：`migratePendingAssetsIfNeeded` 中 `try? fileManager.moveItem`（`ImageHandler.swift` L46）失败被吞，但 `pathMap[filename]` 仍被登记（L47）；随后正文 `![](旧名)` 全部改写为新相对路径（L52-59），最后 `try? removeItem(at: pendingAssetsURL)` 无条件清空临时目录（L61）。
- **问题**：move 失败（目标卷权限/同名占用/沙盒拒写）时：正文已指向新路径而文件不在新位置（坏链），且原临时文件随目录删除被一并清除——文本与文件双失，⌘Z 无法恢复文件（撤销组只针对插入，不针对迁移）。
- **影响**：「粘贴图片→保存」这条 P0 场景链（PRD.md 场景 4）存在静默丢资产路径；与 P4 铁律 4 的精神（文件副作用可逆）不符。
- **建议方向**：重写期将迁移改为事务式：全部 move 成功才改写正文与清理目录；任一失败则中止保存并给可见错误（并入 B5 反馈体系）。

---

## 五、流程 4：查找替换

**理论最快路径**：⌘F → 输入 → Enter/Find Next 逐个 → Replace/Replace All → 明确结果反馈。

**现路径还原**（`SearchReplaceController.swift` L82-152）：面板三按钮行为与逆向报告 ⑥ 流程 6 一致；无命中无提示、正则非法静默（P4 B5 第 4/5 点 + B6 计数缺失）；Replace All 直接重置 `textView.string`（L146-151，P4 B3）。

**五要素**：触发 ✔；前置 ✘（IA-01：keyWindow 非编辑窗口时 ⌘F 静默；IA-02：目标绑定错位）；主路径 ✔；结果反馈 ✘；异常分支 ✘。

### UF-06 面板每次 ⌘F 重建：查询词丢失 + 打开状态下跨窗口错位【B → PL-06，部分升级 P4】

- **当前设计**：`showSearchReplace` if/else 两分支均 `SearchReplaceController(textView:)` 新建（`AppDelegate.swift` L359-368）；`targetTextView` 为 weak 且仅构造时赋值（`SearchReplaceController.swift` L15、L27）。
- **问题**：(a) 每次唤起面板，上次查询词/替换词/正则开关全部归零；(b) 面板不关闭时切换到另一文档窗口，Find Next/Replace 仍作用于旧窗口文本——替换类操作会改错文档。
- **影响**：批量修改场景输入成本翻倍；跨窗口错位是潜在的「改错文件」事故源。P4 未对「面板重建」立案（F-02/B2 为菜单联动、F-06/B6 为计数/Esc，均未涉及该问题），本评审新发现并据 (b) 定为 B。
- **建议方向**：与 IA-02 同源修复：单例面板 + 目标随 key 编辑窗口重绑 + 状态保留；与 B2（菜单联动）、B3（可撤销）、B6（计数）同批。

### 交叉引用

- Replace All 不可撤销/视口重置：P4 F-03/L-02 → B3。
- 面板外续搜断链：P4 F-02/L-01 → B2。
- 无命中/正则非法静默、Esc 未知：P4 F-05/F-06 → B5/B6。

---

## 六、流程 5：导出 HTML / PDF

**理论最快路径**：⌃⌘E → 确认 → 得到文件（成功有反馈）；⌃⌘P → 打印面板 → 存为 PDF。

**现路径还原**（`AppDelegate.swift` L377-411 → `ExportHelper.swift` L15-62）：

1. HTML：keyWindow 守卫 → NSSavePanel 默认名 → `convertToHTML` → `saveToURL` 原子写；失败 DebugLog（L397）；成功亦仅 DebugLog（`ExportHelper.swift` L24）。
2. PDF：markdown → HTML → `PrintableMarkdownView`（WKWebView `loadHTMLString`，L45）→ `NSPrintOperation.run()`；**异步加载与打印时序无等待**【未知，大文档竞态未验证】（逆向报告 ⑨ 已标）。

**五要素**：触发 ✔；前置 ✘（IA-01 keyWindow 路由）；主路径 ✔；结果反馈 ✘（成败均无用户提示，P4 B5 第 1 点）；异常分支 ✘（UF-07）。

### UF-07 PDF 导出对远程图片静默缺图【C → PL-10】

- **当前设计**：entitlements `com.apple.security.network.client=false`（网络禁用）+ WKWebView `loadHTMLString` 渲染含 `![](http://…)` 的文档（`ExportHelper.swift` L45）。
- **问题**：正文引用远程图片时，PDF 输出中该图渲染失败且无提示；HTML 导出（纯文本引用）不受影响，两通道行为不一致。
- **影响**：「导出可靠」（产品 P1 目标）在含远程图文档上不成立，且用户无从得知缺图原因。
- **建议方向**：重写期二选一（用户决策）：导出前扫描远程引用并提示「N 张远程图将被跳过」；或为 WKWebView 单独放行网络（需 entitlement 变更，牵动沙盒最小化原则）。

---

## 七、流程 6：关闭窗口 / 退出应用

**现路径还原**：⌘W → NSDocument 标准三选弹窗（保存/取消/不保存，P4 D4 照旧）；最后窗口关闭 App 驻留（`AppDelegate.swift` L342-346）。

### UF-08 NSSupportsSuddenTermination/AutomaticTermination 声明与保存机制的丢失窗口【C → PL-04】

- **当前设计**：`Supporting Files/Info.plist` 声明 `NSSupportsSuddenTermination=true` 与 `NSSupportsAutomaticTermination=true`；自定义 3 秒 Timer 为唯一自动保存（untitled 完全无覆盖，UF-01）。
- **问题**：Sudden Termination 允许系统在文档「clean」时未经保存流程终止应用——最近 <3 秒的编辑处于无提示丢失窗口；Automatic Termination 与「关最后窗口 App 驻留」的显式设计（F005）存在语义张力（App 空窗驻留时可能被系统自动回收，虽有激活态保护，精确触发条件【未知】）。两项声明在逆向报告与 P4 中均未登记。
- **影响**：极端情况下放大 UF-01/UF-03 的丢失窗口；与「关窗驻留」的产品意图潜在冲突。
- **建议方向**：重写期评估移除两项声明，或仅在确认保存机制（含 untitled autosave）闭环后保留；属工程决策，留用户确认。

### 交叉引用

- 关闭未保存询问系统三选：P4 L-04/D4（维持）。
- 「不保存」关闭后临时图片目录残留：DS-02/PL-14（归数据分册）。

---

## 八、流程五要素完整性总表

| 流程 | 触发 | 前置 | 主路径最短 | 结果反馈 | 异常分支 | 缺口归档 |
|------|:--:|:--:|:--:|:--:|:--:|------|
| 新建→写作→保存 | ✔ | ✔ | ✔ | ✔ | ✘ | UF-01（PL-09） |
| 打开→编辑→自动保存 | ✔ | ✘ | ✔ | ✘ | ✘✘ | UF-02（PL-01）、UF-03（PL-05）、PL-02 |
| 插图→首存迁移 | ✔ | ✘ | ✔ | ✘ | ✘ | UF-05（PL-08）、PM-02 |
| 查找替换 | ✔ | ✘ | ✔ | ✘ | ✘ | UF-06（PL-06）+ P4 B2/B3/B6 |
| 导出 HTML/PDF | ✔ | ✘ | ✔ | ✘ | ✘ | UF-07（PL-10）+ P4 B5 |
| 关闭/退出 | ✔ | ✔ | ✔ | ✔ | △ | UF-08（PL-04）+ P4 D4 |

---

## 九、问题清单汇总（本册新立）

| 编号 | 标题 | 分级 | 映射 PL | 与 P4 关系 |
|------|------|:---:|:---:|------------|
| UF-01 | untitled 文档无自动保存/崩溃恢复 | B | PL-09 | 新发现 |
| UF-02 | 解码失败→欢迎文本文档→autosave 覆盖原文件 | B | PL-01 | **升级** L-03/B5 |
| UF-03 | 外部修改无检测，静默覆盖 | B | PL-05 | 新发现 |
| UF-05 | 首存迁移失败仍改写正文并删临时目录（丢图） | B | PL-08 | 新发现 |
| UF-06 | 查找面板重建丢状态+跨窗口错位 | B | PL-06 | 新发现（P4 未立案面板重建） |
| UF-07 | PDF 远程图片被网络禁令拦截静默缺图 | C | PL-10 | 新发现 |
| UF-08 | Sudden/Automatic Termination 声明的丢失窗口 | C | PL-04 | 新发现 |

（UF-04 编号弃用：沙盒 Recent 可达性问题归权限分册 PM-01，避免双册重复立案。）
