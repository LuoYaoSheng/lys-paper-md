# PaperMD 状态评审

> 评审依据：《AI 产品重构逻辑评审规范 v1.0》 · 2026-09-03
> 输入文档清单：
> 1. `docs/01_reverse/REVERSE_ANALYSIS.md`（④ 页面状态变化、⑦ 状态字段）
> 2. `docs/04_architecture/STATE_MACHINE.md`（P7 状态管理设计 §1-§2、§5）
> 3. `docs/02_product/PAGE_SPEC.md`（1.5 状态与反馈约定、各页「状态列表」维度）
> 4. `docs/06_review/PRODUCT_REVIEW.md`（P4 L-05/D5 专注×侧栏混合态，交叉引用）
> 5. 源码抽查：`PaperMD/App/Document.swift`、`EditorView.swift`、`MarkdownTextView.swift`、`SearchReplaceController.swift`、`PreferencesWindowController.swift`、`AppDelegate.swift`、`Supporting Files/Info.plist`
>
> 本文件为逻辑评审产出之一（ST- 编号问题清单），不修改任何现有文件。状态图用文本绘制，不设计 UI。

---

## 一、状态机 1：文档编辑/保存态（NSDocument changeCount 驱动）

```text
                     ┌───────────────────────────────────────────────┐
                     ▼                                               │
[*] ──新建──> UNTITLED(未绑定fileURL,含欢迎文本)                      │
                 │ 首次输入 updateChangeCount(.changeDone)            │
                 ▼                                               │
            EDITED(脏) <──────── 输入 ──────── CLEAN(已存,干净)     │
                 │ ⌘S: 弹面板→迁移图片→落盘成功                        │
                 └──────────────────────────────> CLEAN             │
                 │ fileURL存在+偏好开: 3s Timer 到时且 isDocumentEdited │
                 │      autosave 成功 ──────────> CLEAN ─────────────┘
                 │      autosave 失败 ──> 仍 EDITED(仅日志,无重试态)
                 │ ⌘W 关闭: 系统三选(保存/取消/不保存) ──> [*]
CLEAN ──再输入──> EDITED
[*] ──打开──> CLEAN(载入)                     (read 成功路径)

异常注入点（本评审新识别，见 ST-01）:
[*] ──打开且解码失败──> 「伪 CLEAN」: fileURL=原文件, textView=欢迎文本,
                        changeCount=0 → 首次输入 3s 后覆盖写回原文件
```

**必要性/重复/冲突/缺失核对**：

| 状态 | 必要性 | 证据 | 判定 |
|------|--------|------|------|
| UNTITLED | 必要（区分是否可自动保存/保存面板默认名） | `Document.swift` L226-235 | ✔ |
| CLEAN | 必要（标题栏脏标消除、autosave 跳过条件） | L195 `isDocumentEdited` | ✔ |
| EDITED | 必要（脏标、Timer 启动） | `EditorView.swift` L219 | ✔ |
| 伪 CLEAN（解码失败） | **不该存在的状态** | L167 + L80-84 组合 | ✘ **ST-01** |
| 只读态 | **缺失**（文件只读/权限丢失仍按可编辑打开） | 全源码无只读分支 | ✘ **ST-02** |
| 保存中/自动保存中态 | 缺失但影响小（写盘同步快速完成） | L197-203 | △ 不立案（观察） |

---

## 二、状态机 2：编辑调度态（EditorEngine，P7 §4 采信并源码复核）

```text
[*] ──> IDLE
IDLE ──textDidChange(非IME)──> DISPATCHING ──afterDelay:0 合并范围──> FORMATTING ──选区恢复──> IDLE
IDLE ──textDidChange(IME marked)──> IME组合(仅统计刷新) ──组合提交──> IDLE
FORMATTING ── isApplyingFormatting 防重入（属性编辑不回流）
偏好变化/主题切换/prepareForDisplay ──全量 reapplyFormatting──> FORMATTING(全范围) ──> IDLE
```

- 复核结论：与 `EditorView.swift` L217-323 逐行一致；两态（IME/防重入）均为 P0 铁律的必要保护，**无冗余、无冲突**。
- 光标/选区在 FORMATTING 前后保存恢复（L267-271、L298-302）✔。

---

## 三、状态机 3：导出态（HTML/PDF）

```text
[*] ──⌃⌘E/⌃⌘P──> {前置检查: keyWindow是否编辑窗口}
     ├─ 失败 ──> [*]（静默返回，无状态残留）
     └─ 通过 ──> PANEL_OPEN(系统SavePanel/PrintPanel)
          ├─ 用户取消 ──> [*]（无副作用，文档状态不变）
          └─ 确认 ──> WRITING(HTML原子写 / WKWebView渲染→打印)
               ├─ 成功 ──> [*]（仅日志，文档状态不变：导出≠保存 ✔）
               └─ 失败 ──> [*]（仅日志）
```

- 判定：导出不污染文档状态 ✔（`AppDelegate.swift` L390-399 不触碰 changeCount）。
- 缺失：WRITING 无进度/无终态反馈（P4 B5 交叉引用）；前置检查失败静默（IA-01/PL-07 交叉引用）；PDF 渲染异步无等待【未知】（逆向 ⑨-13）。

---

## 四、状态机 4：视图态（窗口级）

```text
侧栏: sidebarVisible ∈ {200pt, 0}（toggleSidebar 独立切换）
专注: isFocusMode ∈ {on, off}（on ⇒ 侧栏折叠+状态栏隐藏+工具栏隐藏）
组合空间: {侧栏×专注} 4 格，其中「专注on+侧栏200pt」= 混合态（⌃⌘O 在专注中触发）
退出专注: 无条件恢复侧栏 200pt（无论用户专注前是否手动收起）
```

- 判定：混合态与「退出不记忆用户侧栏偏好」为已知边界，P4 L-05/D5 已立案观察，本册维持交叉引用，不重复计数。

---

## 五、状态机 5：面板态（偏好/查找）

```text
偏好: 单例窗口(isReleasedWhenClosed=false)，改即生效无「应用/取消」态 —— 符合 macOS Settings 惯例 ✔
查找: 名义单例，实际每次 ⌘F 重建 → 无「打开中保持」态
      打开期间: targetTextView 固定于创建时刻的窗口（不随 keyWindow 重绑）
      正则开关 ∈ {on, off}；无「无命中/已回绕/已替换N处」反馈态（P4 B6 交叉引用）
```

### 面板态问题（并入 PL-06）

- **当前设计**：`AppDelegate.swift` L359-368 每次重建；`SearchReplaceController.swift` L27 目标一次性绑定。
- **问题**：状态归属错位——「查找目标」应属文档会话态，实现为面板实例态；多窗口下产生跨文档错位（IA-02/UF-06 已详述）。
- **建议方向**：目标随 key 编辑窗口重绑；FindSession 承载查询态（P7 §2.6 方向一致）。

---

## 六、状态与配置的一致性：autosavesInPlace（ST-03）

- **当前设计**：`override class var autosavesInPlace: Bool { true }`（`Document.swift` L45），类级常量；注释 L42-43 自述「实际由 hasUnautosavedChanges/偏好控制」。偏好 `autosaveEnabled` 仅被自定义 Timer 的两处 guard 读取（L174-176、L183-185）。
- **问题**：系统层语义（类属性）与用户层开关（偏好）脱钩——偏好关闭自动保存时，NSDocument 体系仍认为「就地自动保存启用」，标准触发点（如退出时机的隐式 autosave）是否被偏好挡住【未知——机制组合复杂，源码不可静态确证】。此外自定义 Timer 与系统 autosave 双机制并存，职责边界未定义。
- **影响**：偏好开关的「关」可能存在不被尊重的旁路；两套机制对未来维护者形成认知陷阱。
- **建议方向**：重写期归一为单一机制（推荐：要么全托管给 NSDocument 标准链路并用偏好控制 isAutosaving，要么自定义机制并将类属性改为 false），需用户决策（PL-11）。

---

## 七、问题清单（ST-01…）

### ST-01 「伪 CLEAN 态」：解码失败后内容与文件绑定不一致【B → PL-01】

- **当前设计**：`read(from:)` 失败置 rawText=""（`Document.swift` L167，不抛错不提示）→ `openEditorWindow()` 填欢迎文本（L80-84）→ fileURL 已绑定、changeCount=0、autosave 计时已启动（L174-176）。
- **问题**：状态机出现「非预期复合态」：窗口/标题呈现为已打开的真实文档，内容却是欢迎模板，且处于 CLEAN（无脏标）。用户任何一次输入把它推入 EDITED，3 秒后覆盖写回原文件。
- **影响**：数据破坏链的状态源头；「不变量：磁盘内容恒等于 textView.string 的 UTF-8」（DATA_MODEL.md §2.1）在打开时刻即被破坏。
- **建议方向**：解码失败作为显式错误态处理（不绑 fileURL / 只读打开 + 可见提示），与 UF-02/DS-08 同源同修。

### ST-02 只读文档态缺失【C → PL-12】

- **当前设计**：`Document.swift` 无任何只读分支；page-spec 特检矩阵 14 页中亦无「只读打开」场景。文件只读（权限/锁）时以可编辑态呈现，直到保存才由系统报错（page-spec PAGE011 ✔ 行）。
- **问题**：编辑器最通用的状态之一缺失：只读文件打开后用户可正常输入、看到脏标，形成「能改」的假象，保存时才失败。
- **影响**：低频但困惑度高；与 PL-02（重启后权限失效）叠加时会更常见（书签缺失 → 权限丢失场景增多）。
- **建议方向**：重写期评估：检测文件可写性并进入只读态（标题栏标注、编辑禁用或警告）；属产品取舍，留用户决策。

### ST-03 autosavesInPlace 类属性与偏好开关脱钩、双机制并存【C → PL-11】

- 见 §六详述。建议方向：机制归一，需用户决策。

### ST-04 stopAutosaveTimer 死代码：文档关闭后计时器不显式停止【D → PL-13】

- **当前设计**：`stopAutosaveTimer()`（`Document.swift` L208-211）定义后无任何调用点（grep 证实）；Timer 闭包 weak self + `guard fileURL != nil / isDocumentEdited` 双守卫。
- **问题**：状态清理路径不完整（形式上）；实际风险低（对象释放后闭包自然失效、一次性计时器自灭）。
- **影响**：极小；主要是代码卫生与状态机完备性的瑕疵。
- **建议方向**：观察不动；重写期随机制归一（ST-03）一并处理。

---

## 八、状态冲突/重复全局排查结论

1. **重复状态**：未发现同一语义状态的双源维护（脏标唯一来源 changeCount；高亮为纯派生属性；统计/大纲为派生只读）——「单一事实源+派生只读」纪律（STATE_MACHINE.md §1）在源码中成立。
2. **冲突状态**：唯一的真冲突是 ST-01 伪 CLEAN（内容 vs 绑定）；视图态混合（§四）为已知接受的边界组合。
3. **缺失状态**（按影响排序）：崩溃恢复/草稿态（UF-01/DS-06，流程与数据分册立案）、只读态（ST-02）、自动保存失败重试/退避态（失败仅日志后静默等待下次编辑，P4 B5 范畴）、导出进度/结果态（P4 B5/B6 范畴）。
4. 格式化命令菜单启用态（需选区）与工具栏禁用态同源（`EditorView.swift` L463-485 经 WindowController L263-265 转发）✔ 无漂移。

---

## 九、本册问题汇总

| 编号 | 标题 | 分级 | 映射 PL | 与 P4 关系 |
|------|------|:---:|:---:|------------|
| ST-01 | 解码失败伪 CLEAN 态（覆盖写回的状态源头） | B | PL-01 | 新发现（升级 L-03/B5 的机理描述） |
| ST-02 | 只读文档态缺失 | C | PL-12 | 新发现 |
| ST-03 | autosavesInPlace 与偏好脱钩、双机制并存 | C | PL-11 | 新发现 |
| ST-04 | stopAutosaveTimer 死代码/关闭不停止 | D | PL-13 | 新发现（小） |
