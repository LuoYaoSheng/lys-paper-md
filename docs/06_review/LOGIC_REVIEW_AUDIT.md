# PaperMD 产品逻辑评审（六件套）元审计报告

> 审计性质：独立元审计（只审计 + A 类小错直接修，E 类留档；不改源码/HTML/其他文档；不 commit）
> 审计对象：`docs/product-review/` 六件套（PRODUCT_LOGIC_REVIEW / INFORMATION_ARCHITECTURE_REVIEW / USER_FLOW_REVIEW / DATA_STORAGE_REVIEW / STATE_REVIEW / PERMISSION_REVIEW）
> 审计依据：《AI 产品重构逻辑评审规范 v1.0》（经六件套转述；规范本体未随仓库提供，结构合规按六件套自述条款口径核对）
> 审计日期：2026-09-03　审计人：独立审计员
> 审计范围声明：项目 git 存在 18 条已修改 + 多条未跟踪的既有脏改动（与 QA 报告 §十.3 记录一致），本次未触碰；全部修改仅限六件套本身（见 §四）。

---

## 一、审计结论

**总体：通过（附条件）。** 六件套是一份证据可追溯性极高、跨产物口径高度自洽的产品逻辑评审：

- **证据质量**：行号级抽查 17 组关键发现（覆盖 PL-01…PL-16 全部重点项）**全部与源码精确吻合**，含 4 项 grep 零命中断言的独立复验（外部修改检测/AutosaveInformation/书签 API/只读分支）——无一虚构、无一错行。
- **sed 补修专项**：**零旧路径残留、零误替换**，三类裸名替换（PRD.md / DATA_MODEL.md / STATE_MACHINE.md）在正文中的语义指代全部成立（详见 §七）。
- **发现的实质问题**：1 处头部路径引用错误（`Core/StatusBar.swift`，实际在 `App/`）、5 处对 P4「D1」的失实溯源（PL-06/UF-06 声称「P4 记为 D1 小缺陷」，P4 的 D1 实为格式化三处重复实现，且 P4 全文未涉及面板重建）——均已作为 A 类直接修复。
- **留档问题**：E 类 3 项（§14 评审重点无对应章节、§8 条款标注在总报告与 DS 分册间冲突、`docs/06_review/UX_REVIEW.md` 存在同样 D1 失实但超出本次修复范围），见 §五。

**结构合规度约 92.6%**（口径：13 个评审重点显式映射 12/13 + 分册立案条目四段完整 22/25）；**证据抽查通过率 17/17（100%，行号级）**；**分级合理性抽查 25 项零失当**。

---

## 二、四维审计结果

### A. 结构合规（对照规范自述条款）

| 检查点 | 结果 | 明细 |
|--------|------|------|
| 1. 六文件齐全 + 头部三要素 | **通过** | 6/6 文件存在；头部均含评审依据（规范名+版本）、日期 2026-09-03、编号输入清单（文档+源码双列） |
| 2. 四段式覆盖率 | **88%（22/25）** | IA 2/2、UF 7/7、ST 4/4、PM 4/4 完整；DS 5/8（DS-07/DS-08 缺独立「影响」段，DS-06 归并 UF-01 压缩处理——均有同源归并说明，非无理由缺段）。总报告 PL-01…16 为汇总表形态（五列），四段正文委托分册承载，属结构分工而非缺失 |
| 3. §17 八项验收清单 | **通过** | §十逐项「结论+关键依据」8/8 齐备；总评（输入主链路严密/文档可靠性与异常兜底不达标）与逐项结论自洽 |
| 4. 视角合规 | **通过** | 状态机/导航层级图为文本结构图（非 UI 设计稿）；全文仅引用行号与代码事实，未生成代码；建议均为「重写期方向」（无直接改源码指令）；UF-04 弃用编号有明示 |
| 5. §2-§14 十三重点映射 | **12/13** | 见 §六映射表；缺失：**§14 无对应章节**（E-1）。另发现 §8 条款标注内部冲突（E-2） |

### B. 证据可追溯性

- 抽查 17 组关键发现（见 §五前「证据抽查记录表」→ 实为 §八）：文件存在性 27/27（修复后），行号内容支持 17/17 组，**无一 E 级证据错误**。
- 4 项 grep 断言独立复验全部成立：`NSFileVersion|fileModificationDate|revertToSaved` 零命中（PL-05）；`AutosaveInformation` 零命中（PL-09）；`bookmark|SecurityScoped|startAccessing` 零命中（PL-02/PM-01）；Document.swift 无只读分支（PL-12）。
- entitlements 全文 3 键（app-sandbox / user-selected.read-write / network.client=false）与 Info.plist 关键键（双终止声明 true / NSDisableWindowRestoration true）逐键核实。
- 【未知】标记使用规范：共 6 处（PL-03/PM-02 沙盒可达性、PL-11/ST-03/PM-04 双机制组合行为、UF-07 打印时序竞态、UF-08 终止触发条件、IA 抽查⑩ Esc 行为），**全部给出不可静态确证的理由或规范出处**（如「静态评审无法确证，需实测」「P4 F-06 已标注未知，交叉引用」），无滥用（未发现用【未知】回避可静态验证的问题），亦无漏标（静态断言处均未发现越界断言）。

### C. 跨产物一致性

| 检查点 | 结果 | 明细 |
|--------|------|------|
| 8. P4 编号存在性 | **通过（修复后）** | 引用的 F-01/02/03/05/06、P-01/03/04/05、L-01…L-06、B1-B8、C1-C7、D1-D7、A2、SV-01…SV-06 在 `docs/06_review/PRODUCT_REVIEW.md` 全部存在且语义相符。**例外**：PL-06/UF-06 声称「P4 记为 D1 小缺陷」失实（P4 的 D1=F-08 格式化三处重复；P4 全文无「重建」「小缺陷」字样）→ 已修（A-2） |
| 9. sed 补修专项 | **通过** | 见 §七专项结论 |
| 10. 与 HTML_QA_REPORT 冲突 | **无冲突，互补一致** | QA P2-1 的对象是 **V1 原型**（broken-encoding alert 声称「不进自动保存计时」，实测仅对「打开动作」成立，用户一旦编辑 `S.fileName` 非空使计时照常启动）；PL-01/UF-02 的对象是**真机源码**（解码失败→欢迎模板→fileURL 绑定→3 秒覆盖写回）。QA §九口径注明「真机为欢迎模板填入+3 秒覆盖（USER_FLOW 旅程 2 UF-02）」与 UF-02 对真机的还原**逐点一致**；QA §五旅程 2-UF02 亦显式标注「V1 为修复规格：真机填欢迎模板」。两份报告分别覆盖真机缺陷层与原型修复规格层，层次不同、口径互证，不构成矛盾。且 QA 实测「编辑后照常保存」恰恰复现并强化了 PL-01 的风险判断（修复规格未完全落实） |
| 11. 与 v2.0 新产物口径 | **一致** | ① `docs/03_flow/USER_FLOW.md`：UF-01/02/03/05/06/07 编号与 B/C 分级同源一致，旅程 2 显式注明「补充自 USER_FLOW_REVIEW.md §三 UF-02 对 Document.swift L80-84/L167 的还原」；② `docs/05_sequence/SEQUENCE_DIAGRAMS.md` 图 5「外部修改冲突路径（UF-03）」与 UF-03 口径一致，其 grep 零命中断言经独立复验成立；③ `docs/08_development/PERMISSION.md` PM-01…PM-04 逐项一致（含【未知】标注与 PL 映射）；④ `docs/08_development/ERROR_CODE.md` 引用的 ImageHandler L33/L35/L44/L46/L61 与 Document L167 经复验全部正确，PMD-D01/D03/A02 的修复方向与 PL-01/PL-05/PL-08 建议方向一致 |

### D. 分级合理性

- 抽查 25 项（16 项 PL 全量 + 分册同源 9 项），**零失当**：
  - **数据破坏级核实**：PL-01（解码失败覆盖写回）、PL-08（迁移失败删原图）、PL-05（外部修改静默覆盖）、PL-09（untitled 崩溃全丢）均为 **B（重构落地）** ✔——与「数据丢失/覆盖属编辑器底线、必须进 V1 重构范围」的定级逻辑一致，无降级避重。
  - 同源问题跨册同级一致：DS-01/UF-05/PL-08 同 B；DS-04/PM-01/PL-02 同 B；DS-05/PL-06 同 B；DS-06/UF-01/PL-09 同 B；DS-07/UF-03/PL-05 同 B；DS-08/ST-01/UF-02/PL-01 同 B；DS-02/PL-14 同 D；DS-09/PL-16 同 D；ST-02/PL-12 同 C；ST-03/PM-04/PL-11 同 C；ST-04/PL-13 同 D。
  - C 类均有真实用户决策点（PL-03 实测前置、PL-04 声明取舍、PL-10 二选一、PL-11 机制归一、PL-12 只读取舍）；D 类均为低风险观察项（死代码/tmp 残留由系统清理/会话恢复成本）；PL-15 文档矛盾定 A（勘误）并声明「待授权执行」符合评审性质。
  - PL-06 定 B 的依据（跨窗口改错文档事故源）独立成立，不依赖已修正的「升级」叙事。

---

## 三、A 类修复清单（已直接执行，共 6 处、两类）

| # | 文件 | 位置 | 修复内容 | 依据 |
|---|------|------|----------|------|
| A-1 | PRODUCT_LOGIC_REVIEW.md | 头部输入清单第 5 条 | `Core/StatusBar.swift` → `App/StatusBar.swift` | StatusBar 类与 DocumentStats 结构体均定义于 `PaperMD/App/StatusBar.swift`（L10/L104）；`PaperMD/Core/` 下无该文件。属原始引用错误，非 sed 残留（修复时保留原清单中 Info.plist/entitlements 两项不变） |
| A-2a | PRODUCT_LOGIC_REVIEW.md | §十一 PL-06 行「P4 关系」列 | 「部分升级（P4 记「小缺陷」入 D1；跨窗口错位为新发现）」→「新发现（P4 未立案「面板重建」——F-02/B2 为菜单联动、F-06/B6 为计数/Esc，均未涉及；本评审据跨窗口错位定为 B）」 | P4 的 D1=F-08 格式化三处重复实现；P4 全文无「重建」「小缺陷」字样，查找面板相关仅 F-02（B2 联动）与 F-06（B6 计数/Esc），均未涉及面板重建问题 |
| A-2b | PRODUCT_LOGIC_REVIEW.md | §十一「与 P4 评审的关系汇总」 | 删除「部分升级：PL-06」条目，PL-06 并入「新发现」并将统计 13 项改为 14 项（含归因说明） | 同上；保持汇总统计自洽 |
| A-2c | USER_FLOW_REVIEW.md | §五 UF-06「影响」段 | 「P4 将重建问题记为小缺陷（D1 归位），本评审据 (b) 建议升为 B」→「P4 未对「面板重建」立案（F-02/B2 为菜单联动、F-06/B6 为计数/Esc，均未涉及该问题），本评审新发现并据 (b) 定为 B」 | 同上 |
| A-2d | USER_FLOW_REVIEW.md | §九 汇总表 UF-06 行 | 「**部分升级**（P4 记 D1 小缺陷）」→「新发现（P4 未立案面板重建）」 | 同上 |

> 修复后复验：六件套内「Core/StatusBar」「记 D1」「入 D1」「D1 归位」「D1 小缺陷」字样清零；PL-06 仍为 B 级（依据独立成立），分级与统计自洽。所有修改仅限 docs/product-review/ 两份文件，git 范围确认未触碰其他文件（两目录均为未跟踪新产物，未 commit）。

---

## 四、E 类清单（留档，未修复）

| # | 问题 | 位置 | 建议处置 |
|---|------|------|----------|
| E-1 | **§14 评审重点无对应章节**：总报告 L20 声称「按规范 §2-§14 的 13 个评审重点逐项走查」，但正文仅显式映射 §2-§13（12 项），§14 无任何章节或条目承载 | PRODUCT_LOGIC_REVIEW.md §一/§二-§九 | 主线核对规范 §14 真实条款后补章或在 §一声明该条的覆盖方式。规范本体未随仓库提供，审计无法代补（不得虚构规范内容） |
| E-2 | **§8 条款标注内部冲突**：总报告 §六将 §8 归「跳转导航与信息架构」（§7-§8 合并走查），DATA_STORAGE_REVIEW §二却标注「自动保存机制专项核对（§8）」——同一条款号在两册指向不同评审域，至少一处标注错误 | PRODUCT_LOGIC_REVIEW.md §六 vs DATA_STORAGE_REVIEW.md §二 | 规范不可得，无法判定何者正确，故不擅改（若擅改可能引入新错误）。建议主线以规范原文核定 §8 语义后统一（DS 册 §三「§9 数据生命周期」与总报告 §七「§9-§10 数据与状态」兼容，冲突仅在 §8） |
| E-3 | **UX_REVIEW.md 同源 D1 失实**：`docs/06_review/UX_REVIEW.md` L66「查找面板重建丢状态+跨窗口错位 \| D1（P4 原记小缺陷）」与六件套原错误同源（P4 无此记录） | docs/06_review/UX_REVIEW.md L66 | 超出本次「只改六件套」的修复授权，留档待主线同步修正（其「UF-06 升级为 B」的结论本身与六件套修复后口径不冲突，仅溯源表述失实） |

> 另记结构性部分合规（不计 E 类错误）：DATA_STORAGE_REVIEW 的 DS-07/DS-08 缺独立「影响」段（各有当前设计/问题/建议方向三段）、DS-06 归并 UF-01 压缩展开——均附同源指引，属压缩处理而非遗漏；规范如严格要求逐条四段，可在重排版时补齐。

---

## 五、证据抽查记录表（17 组，全部通过）

| # | 发现 | 声称证据 | 复验结果 |
|---|------|----------|----------|
| 1 | PL-01 解码失败→欢迎模板→autosave 覆盖链 | `Document.swift` L80-84、L166-177、L188-206（核心 L167） | ✔ L80-84 精确为 rawText 空→欢迎文本 `# Hello PaperMD…` 分支；L167 `String(data:encoding:.utf8) ?? ""` 不抛错；L174-176 fileURL+偏好启动计时；L193 3.0s Timer |
| 2 | PL-02 沙盒无书签→Recent 跨启动失效 | entitlements；`AppDelegate.swift` L333-340；全源码无 bookmark API | ✔ entitlements 全文仅 3 键；L333-340 openRecentDocument 错误分支仅 DebugLog；grep bookmark/SecurityScoped/startAccessing 零命中 |
| 3 | PL-03 同级 `.assets/` 授权可达性【未知】 | `ImageHandler.swift` L131-138 | ✔ L134-137 已保存文档在 documentURL 同目录 createDirectory（try? 吞错）；L120-128 兜底分支与 PM-02 描述一致 |
| 4 | PL-04 双终止声明丢失窗口 | `Supporting Files/Info.plist`；`Document.swift` L188-206 | ✔ Info.plist L27-30 NSSupportsAutomaticTermination/SuddenTermination 均 true |
| 5 | PL-05 外部修改无检测静默覆盖 | `Document.swift` L144-177；grep 无冲突检测 | ✔ grep `NSFileVersion\|fileModificationDate\|revertToSaved` 全源码零命中（独立复验） |
| 6 | PL-06 面板重建丢状态+跨窗口错位 | `AppDelegate.swift` L359-368；`SearchReplaceController.swift` L15、L27、L146-151 | ✔ L362-365 if/else 两分支均 new；L15 weak targetTextView 构造时一次性绑定；L146-151 Replace All 直接重置 textView.string |
| 7 | PL-07 命令路由 keyWindow 前置 | `AppDelegate.swift` L359-361、L377-381、L403-405 | ✔ 三处 guard keyWindow+EditorView 失败即 return（exportToHTML 的 currentDocument 仅取默认名 L378-386 亦属实） |
| 8 | PL-08 迁移失败仍改写正文并删临时目录 | `ImageHandler.swift` L39-61（L46 try?、L61 无条件 removeItem） | ✔ L46 `try? moveItem` 失败被吞；L47 pathMap 仍登记；L52-59 正文按 pathMap 改写；L61 `try? removeItem(pendingAssetsURL)` 不检查迁移成败。数据双失链条源码层面完整成立 |
| 9 | PL-09 untitled 无自动保存/崩溃恢复 | `Document.swift` L194（guard fileURL）；无 AutosaveInformation | ✔ L194 `guard let self = self, self.fileURL != nil`；grep AutosaveInformation 零命中 |
| 10 | PL-10 PDF 远程图静默缺图 | entitlements network.client=false；`ExportHelper.swift` L40-46 | ✔ entitlements 显式 false；L45 `webView.loadHTMLString(html, baseURL: nil)` |
| 11 | PL-11 autosavesInPlace 与偏好脱钩 | `Document.swift` L45、L42-44 注释 | ✔ L45 类属性恒 true；注释 L42-43；偏好仅 L174-176/L183-185 两处 guard 读取 |
| 12 | PL-12 无只读文档态 | `Document.swift` 无只读处理 | ✔ grep readOnly/isReadOnly 零命中 |
| 13 | PL-13 stopAutosaveTimer 死代码 | `Document.swift` L208-211（无调用） | ✔ 全源码仅定义一处，零调用点 |
| 14 | PL-14 不保存关闭后 tmp 目录残留 | `ImageHandler.swift` L145-149 | ✔ L145-149 temporaryDirectory + `PaperMD-{UUID}.assets`；清理点仅 L61 迁移与 L218-226 撤销 |
| 15 | PL-15 产品说明「最多 10 个」矛盾 | `docs/产品说明.md` 5.1.1；`AppDelegate.swift` L307-331 | ✔ 产品说明 5.1.1 明载「最近打开列表（最多 10 个）」；L307-331 recentDocumentURLs 系统托管无文档级上限控制 |
| 16 | PL-16 窗口恢复禁用+无现场恢复 | `Info.plist` NSDisableWindowRestoration；`Document.swift` L39-40 | ✔ 两处均属实（L39-40 encode/restoreState 空实现） |
| 17 | IA/DS/PM 支撑引用（抽查⑥⑦⑩、IA-03、SV/权限表） | EditorView L157-162/L219/L463-485、OutlineView L137-141、PWC L239-241、MarkdownTextView L59-65/L102-122/L344-354、ExportHelper L22-25/L52-61、WindowController L58-195/L213-259、AppDelegate L180-185/L103/L124 | ✔ 逐处核对全部吻合（含 ⌘G 系统动作 L180-185、状态栏 bounds.height-28 顶部布局、偏好 3 键定义行） |

**通过率：17/17 = 100%（行号级）。** 含 27 个被引文件存在性验证：26 个原生通过，1 个（`Core/StatusBar.swift`）为路径引用错误且不属于 17 组发现证据（系头部输入清单笔误），已列 A-1 修复。

---

## 六、规范 §2-§14 十三个评审重点映射表

| 规范条款 | 评审重点 | 承载位置 | 覆盖结论 |
|----------|----------|----------|----------|
| §2 | 产品目标 | 总报告 §二（逐目标核对表：P0 输入/撤销、P1 文件即文档/导出、P2 UI） | ✔ |
| §3 | 用户目标最快路径 | 总报告 §三（7 场景理论最快 vs 现路径对照表） | ✔ |
| §4 | 页面合理性 | 总报告 §四（14 页面存在理由）+ IA §二归属表 | ✔ |
| §5 | 页面职责 | 总报告 §四 + IA §二/§三（职责混杂定位到命令路由层） | ✔ |
| §6 | 流程完整性五要素 | 总报告 §五摘要 + USER_FLOW_REVIEW 全册（6 流程×5 要素总表） | ✔ |
| §7 | 跳转导航可预测性 | 总报告 §六 + IA §一导航层级图/§四抽查 10 例 | ✔ |
| §8 | 信息架构 | 总报告 §六（§7-§8 合并）+ IA 全册 | ✔ 覆盖，但条款标注冲突见 E-2 |
| §9 | 数据 | 总报告 §七 + DATA_STORAGE_REVIEW §一清单/§三生命周期 | ✔（DS 册将 §9 标为「数据生命周期」，与总报告 §9-§10 口径兼容） |
| §10 | 状态 | 总报告 §七 + STATE_REVIEW 全册（5 状态机+冲突/重复/缺失排查） | ✔ |
| §11 | 权限 | 总报告 §八 + PERMISSION_REVIEW 全册（11 项权限清单+沙盒推演） | ✔ |
| §12 | 异常流程 | 总报告 §八（7+2 静默失败族）+ UF 各流程异常分支 | ✔ |
| §13 | 功能取舍 | 总报告 §九（6 取舍点对照表） | ✔ |
| **§14** | **（规范条款名不可考）** | **无对应章节** | **✘ 缺失（E-1）** |
| §17 | 八项验收清单 | 总报告 §十（8/8 结论+依据） | ✔ |

**缺失清单：§14（1 项）。**

---

## 七、sed 补修专项结论

**专项背景**：六件套旧路径引用曾由主线以 sed 批量补修（prd.md→PRD.md、data-model.md→DATA_MODEL.md、state-management.md→STATE_MACHINE.md 等裸名/路径替换）。

**① 零旧路径残留：通过。**
对六件套全量 grep 小写连字符裸名形态（prd.md / page-spec.md / data-model.md / state-management.md / reverse-analysis.md / product-review.md / module-arch.md 等全部可枚举旧形态）及旧目录结构形态（docs/review、docs/design、docs/architecture 等）：**零命中**。正文中出现的「page-spec」「PRD.md」等均为正确新路径或语义指代（指 `docs/02_product/PAGE_SPEC.md`、`docs/02_product/PRD.md`），非残留。六件套引用的全部 27 个文件/路径经存在性验证均真实（唯一例外 `Core/StatusBar.swift` 为头部清单原始笔误，与 sed 替换无关，已修 A-1）。

**② 替换处上下文通顺、无误替换：通过。** 三类裸名替换逐处核查：

| 替换对 | 出现处 | 语义指代核验 |
|--------|--------|--------------|
| prd.md → `docs/02_product/PRD.md` | 六册头部清单 + UF/PL 正文「PRD.md §2 画像/§3 场景/F008」 | ✔ PRD.md 存在，§2 用户画像、§3 使用场景、§5 F008 功能行内容与引用语义相符（UF-01 引 F008「自动保存：偏好开关，3 秒无操作落盘」未限定已保存文档的批评成立） |
| data-model.md → `docs/08_development/DATA_MODEL.md` | PL/DS 头部 + DS-05「§2.6 FindSession」+ ST-01「§2.1 不变量」 | ✔ 文件现位于 docs/08_development/；**§2.1 实有「不变量：磁盘内容恒等于 textView.string 的 UTF-8 编码」**（ST-01 引用指代精确成立）、**§2.6 实有 FindSession（V1 新增 B2/B3/B6）**（DS-05/ST 面板态建议方向引用成立）。正文按「数据模型文档」语义引用处指代无误 |
| state-management.md → `docs/04_architecture/STATE_MACHINE.md` | PL/ST 头部 + ST §八「§1 单一事实源纪律」 | ✔ 文件已改名并位于 docs/04_architecture/；**§1 实有「原则：单一事实源 + 派生只读」**（ST §八引用成立）；ST 头部「P7 状态管理设计 §1-§2、§5」的章节结构（§1 状态分布/§2 NSDocument 体系/§5 UI 状态归口）均存在。正文按「状态管理文档」语义引用处指代无误 |

**专项结论：sed 补修零残留、零误替换、零语义断裂；唯一路径错误（Core/StatusBar.swift）系评审写作时的原始笔误而非 sed 产物，已修正。**

---

## 八、阻塞说明

本次审计**无阻塞**。E 类 3 项均为留档改进项，不构成对六件套结论可信度的实质损害；唯一影响可信度的失实溯源（PL-06/UF-06 的 D1 归属）已修复，且该修复不改变任何分级与处置结论。
