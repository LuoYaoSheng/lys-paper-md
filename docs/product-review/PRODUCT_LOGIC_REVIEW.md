# PaperMD 产品逻辑评审总报告

> 评审依据：《AI 产品重构逻辑评审规范 v1.0》 · 2026-09-03
> 输入文档清单：
> 1. `docs/01_reverse/REVERSE_ANALYSIS.md`（P2 逆向分析报告 v1.0，2026-09-02）
> 2. `docs/02_product/PRD.md`（P3 PRD v1.0-rebuild）
> 3. `docs/02_product/PAGE_SPEC.md`（P3 页面交互规格 v1.0-rebuild）
> 4. `docs/06_review/PRODUCT_REVIEW.md`（P4 产品体验审查报告 v1.0，已有 A/B/C/D 编号——本次交叉引用避免重复）
> 5. 源码抽查：`PaperMD/App/Document.swift`、`AppDelegate.swift`、`EditorView.swift`、`MarkdownTextView.swift`、`ImageHandler.swift`、`ExportHelper.swift`、`SearchReplaceController.swift`、`WindowController.swift`、`PreferencesWindowController.swift`、`PaperMDDocumentController.swift`、`Core/TextSearch.swift`、`App/StatusBar.swift`（DocumentStats 所在，见 StatusBar.swift）、`Supporting Files/Info.plist`、`Supporting Files/PaperMD.entitlements`
> 6. 佐证：`docs/04_architecture/STATE_MACHINE.md`、`docs/08_development/DATA_MODEL.md`、`CLAUDE.md`、`docs/产品说明.md`
>
> 评审性质：只评审、不修改。除本目录 6 个文件外未改动任何现有文件。规范文档本体未随仓库提供，按任务给定的条款结构（§2-§14 评审重点、§17 八项验收清单）执行。
> 铁律遵守：未设计 UI、未生成代码、未改 HTML 原型；无法证实的结论标【未知】。

---

## 一、评审范围与方法

- 对象：PaperMD v1.0/v1.1（Swift + AppKit + TextKit 1 的 macOS Markdown 编辑器），以源码为最终事实源，文档与代码矛盾处以代码为准（沿用 PRD.md 的对齐原则）。
- 方法：按规范 §2-§14 的 13 个评审重点逐项走查；每个发现给出「当前设计 / 问题 / 影响 / 建议方向」四段式；分级沿用项目既有 A/B/C/D（A=文档勘误、B=重构落地、C=需用户决策、D=观察不动），产出以 B/C 为主。
- 编号规则：本报告汇总编号 **PL-01…**；分册编号 IA-（信息架构）、UF-（用户流程）、DS-（数据存储）、ST-（状态）、PM-（权限）。与 P4 既有编号（F-/P-/L-/A2/B1-B8/C1-C7/D1-D7）交叉引用的不重复计数，仅标注升级关系。

---

## 二、§2 产品目标核对

当前设计（依据 CLAUDE.md「Project Overview/Core Philosophy」、docs/产品说明.md §3、README.md）：

- P0：输入零卡顿、光标 100% 可预测、中文 IME 稳定、每个结构变更可撤销。
- P1：文件即文档（本地优先）、导出可靠（PDF/HTML）。
- P2：美观克制的原生 UI。

逐项核对结论：

| 目标 | 逻辑一致性结论 | 证据 |
|------|----------------|------|
| 输入零卡顿/光标可预测 | 通过。单一事实源（NSTextStorage.string）+ 行级增量 + IME 跳过重排，无反向写回路径 | `EditorView.swift` L217-235、`CLAUDE.md` Source of Truth |
| 每个结构变更可撤销 | **不通过（1 处违规）**：Replace All 直接重置 `textView.string` | `SearchReplaceController.swift` L146-151（P4 F-03/B3 已立案，交叉引用） |
| 文件即文档、本地优先 | **部分不通过**：文件即文档成立（无私有格式），但「本地优先」的可达性被沙盒无书签削弱——跨启动最近文档不可达 | `PaperMD.entitlements`（无 bookmarks 键，见 PM-01/PL-02） |
| 导出可靠 | **部分不通过**：导出成功/失败均无用户反馈；PDF 对远程图片静默缺图 | `AppDelegate.swift` L394-398；`PaperMD.entitlements` network.client=false（见 UF-07/PL-10） |

问题（PL 汇总见 §十）：产品目标本身自洽且克制；主要逻辑风险不在目标层，而在「数据不丢失」这一编辑器的隐含底线目标上——本评审发现 3 条新的数据丢失/覆盖路径（PL-01、PL-05、PL-08、PL-09），均无用户可见反馈兜底。

---

## 三、§3 用户目标：最快路径 vs 现路径

核心用户目标逐条对比（依据 PRD.md §3 七场景 + 源码验证）：

| 用户目标 | 理论最快路径 | 现路径 | 步数差 | 结论 |
|----------|--------------|--------|--------|------|
| 快速开写 | 双击 App → 直接可打字 | 启动 → ensureDocumentAndWindowVisible → 新 Document → 窗口 + 欢迎文本 + 聚焦 | 0 | 通过（`AppDelegate.swift` L55-87、`Document.swift` L80-86） |
| 写作→保存 | ⌘S（已有文件） | 同左，直接落盘 | 0 | 通过（`Document.swift` L139-142） |
| 写作→另存 | ⇧⌘S 面板确认 | 同左 | 0 | 通过 |
| 写作→导出 HTML | ⌃⌘E → 确认 | 同左 | 0 | 通过（`AppDelegate.swift` L377-401） |
| 打开最近文件 | Open Recent → 点选 | 同左，但**跨 App 重启后该路径必然失败**（沙盒无书签，静默日志） | +N（退回 ⌘O 浏览） | **不通过**（`AppDelegate.swift` L333-340 + entitlements，见 PL-02） |
| 长文导航 | 大纲点击/⌘F 查找 | 大纲 ✔；查找的「面板外续搜」断链 | +1 | 部分通过（P4 B2 交叉引用） |
| 插入图片 | ⌘V 自动落盘 | 同左；但**已保存文档在沙盒下创建同级 `.assets/` 目录可能被拒**（静默不插入）【运行时行为未知，见 PM-02】 | — | 待验证 |

结论：核心写作主链路（开写、保存、导出）路径最短、无多余页面；偏差集中在「再次到达」（Recent 失效）与「异常可达性」（静默失败无反馈）两点。

---

## 四、§4-§5 页面合理性与页面职责（摘要）

14 个页面（PAGE001-014）均能回答「为什么存在」；无建议删除、合并、拆分的页面。PAGE002 菜单与 PAGE006 工具栏为同源命令双入口，属 macOS 惯例而非重复（与 P4 P-05 结论一致）。职责混杂问题集中在**命令路由层**而非页面层：

- PL-07（IA-01）：导出/查找等全局命令依赖 keyWindow 恰好是编辑窗口，偏好或查找面板聚焦时静默无响应（`AppDelegate.swift` L359-361、L377-381、L403-405）。
- PL-06（IA-02/ST 面板态）：查找面板为独立自由窗口，与目标文档窗口的从属关系未定义，切换窗口后仍作用于旧文档。

详见 `INFORMATION_ARCHITECTURE_REVIEW.md`。

---

## 五、§6 流程完整性五要素（摘要）

按「触发 / 前置条件 / 主路径 / 结果反馈 / 异常分支」五要素走查 6 条核心流程，结论：

| 流程 | 触发 | 前置 | 主路径 | 结果反馈 | 异常分支 |
|------|:---:|:---:|:---:|:---:|:---:|
| 新建→写作→保存 | ✔ | ✔ | ✔ | ✔（标题栏脏标） | **缺崩溃恢复（PL-09）** |
| 打开→编辑→自动保存 | ✔ | ✔ | ✔ | ✘ 静默落盘（macOS 惯例可接受） | **解码失败反成覆盖路径（PL-01）；外部修改无检测（PL-05）** |
| 插图→首存迁移 | ✔ | ✔ | ✔ | ✘ | **迁移失败仍改写正文并删临时目录（PL-08）** |
| 查找替换 | ✔ | ✔ | ✔ | ✘ 无命中/计数反馈（P4 B5/B6） | ✘ 正则非法静默（P4 B5）；**面板重建丢查询词、跨窗口错位（PL-06）** |
| 导出 HTML/PDF | ✔ | **隐含前置未定义（keyWindow）** | ✔ | ✘ 成败均无提示（P4 B5） | **PDF 远程图片静默缺图（PL-10）** |
| 关闭/退出 | ✔ | ✔ | ✔ | ✔（系统三选，P4 D4） | **Sudden Termination 与 <3s 编辑窗口（PL-04）** |

详见 `USER_FLOW_REVIEW.md`。

---

## 六、§7-§8 跳转导航与信息架构（摘要）

- 菜单（PAGE002）7 顶级结构符合 macOS 惯例；跳转关系在 PAGE_SPEC.md 已矩阵化。
- 可预测性抽查 10 例：6 例可预测、3 例不可预测、1 例未知（详见 IA 分册 §四）。不可预测项分别对应：⌘G 系统动作脱离自研面板（P4 B2）、偏好窗聚焦时 ⌃⌘E 无响应（PL-07）、工具栏 Heading 图标语义与恒 H1 行为不一致（P4 B1 关联）。
- 导航层级图与逐窗口分类归属表见 `INFORMATION_ARCHITECTURE_REVIEW.md`。

---

## 七、§9-§10 数据与状态（摘要）

数据分类核对：文档内容（应存、磁盘 ✔）、图片资产（应存、`.assets/` ✔ 但迁移/清理有缺口）、偏好（应存、UserDefaults 3 键 ✔）、最近文件（应存、系统托管但**沙盒下跨启动不可用**）、撤销栈（不持久、符合预期）、查找会话（不持久且被重建逻辑放大为缺陷）。无草稿/会话数据被不当持久化。

生命周期核对发现的缺口：未保存变更无崩溃恢复（PL-09）、临时图片目录不清理（PL-14）、外部修改无检测（PL-05）。详见 `DATA_STORAGE_REVIEW.md`。

状态核对：文档态机（Untitled/Clean/Edited）基本成立；发现「解码失败伪 Clean 态」（PL-01 根因，ST-01）、只读态缺失（PL-12）、autosavesInPlace 类属性与偏好开关脱钩（PL-11）。详见 `STATE_REVIEW.md`。

---

## 八、§11-§12 权限与异常流程（摘要）

权限模型最小化良好（沙盒开、仅用户选择文件读写、网络关闭、无多余 entitlement）。两个缺口：

1. 无 security-scoped bookmark → 最近文档跨启动必然失败（PL-02，B）。
2. `{doc}.assets/` 同级目录创建在「用户仅授权单文件」场景下的沙盒可达性【未知，需实测】（PL-03，C）。

异常流程共核出 7 处静默失败（P4 B5 已立案 7 点，本次确认源码属实）并新增 2 处：PDF 远程图片被网络禁令拦截（PL-10）、导出命令前置条件失败静默返回（PL-07）。详见 `PERMISSION_REVIEW.md`。

---

## 九、§13 功能取舍

| 取舍点 | 现状 | 评审意见 |
|--------|------|----------|
| H4-H6 入口 | 高亮/大纲支持，命令入口止步 H3 | 维持 P4 B1 处置（补入口，非新增功能） |
| togglePreview 死代码 | 无 UI 入口空壳 | 维持 P4 C1（用户决策） |
| 欢迎文本预填 | 新文档默认填入 | 维持 P4 D6，但须与 PL-09（untitled 崩溃恢复缺失）合并考虑——欢迎文本降低了用户「先保存」的警觉 |
| 窗口恢复禁用 | NSDisableWindowRestoration=true | 本地优先+文件即文档下自洽；与 PL-02 叠加后「重启后回到工作现场」成本全在用户（D 观察并入 PL-16） |
| 3 秒自动保存仅限已保存文档 | guard fileURL != nil | 逻辑上有意（untitled 无处可存），但缺崩溃恢复配套 → PL-09 |
| 拼写连续检查关闭、Help 无 book | 部分实现 | 维持 P4 C2 / D 观察不变 |

---

## 十、§17 八项验收清单逐项结论

| # | 验收项 | 结论 | 关键依据 |
|---|--------|------|----------|
| 1 | 每个页面/面板都能回答「为什么存在」 | **通过** | 14 页面逐一核对（IA 分册 §三），无冗余页面 |
| 2 | 核心用户目标存在最短完成路径 | **部分通过** | 写作/保存/导出最短；「再次到达」因 PL-02 断链 |
| 3 | 核心流程五要素完整 | **不通过** | 异常分支系统性缺失：PL-01/05/08/09 + P4 B5 七点 |
| 4 | 跳转导航可预测 | **部分通过** | 抽查 10 例 3 例不可预测（IA 分册 §四） |
| 5 | 数据分类正确、位置合理、生命周期闭环 | **不通过** | 生命周期不闭环：崩溃恢复缺失（PL-09）、临时目录不清理（PL-14）、迁移失败丢图（PL-08） |
| 6 | 关键状态齐备且互不冲突 | **部分通过** | 文档态机成立；缺只读态（PL-12）、存在伪 Clean 态（ST-01） |
| 7 | 权限最小且满足功能 | **不通过** | 功能（Open Recent）已被权限模型打断（PL-02）；assets 目录可达性未验证（PL-03） |
| 8 | 异常与边界有兜底反馈、无致死静默路径 | **不通过** | 存在 3 条「静默→数据丢失/覆盖」路径（PL-01、PL-05、PL-08） |

总评：**输入体验主链路（产品核心价值）逻辑严密；文档可靠性与异常兜底（编辑器隐含底线）不达标**，是重构期必须收口的板块。

---

## 十一、问题汇总表（PL-01…）

> 「关联」列为本评审分册编号；「P4 关系」说明与既有评审的交叉引用或升级。

| PL | 标题 | 分级 | 关联 | P4 关系 | 证据（源码路径） |
|----|------|:---:|------|---------|------------------|
| PL-01 | 非 UTF-8 文件解码失败后加载欢迎文本形成「伪文档」，自动保存将其覆盖写回原文件 | **B** | UF-02、ST-01、DS-08 | **升级** L-03/B5（P4 记为「静默空文档」，实际更重：欢迎文本+绑定 fileURL+自动保存） | `Document.swift` L80-84、L166-177、L188-206 |
| PL-02 | 沙盒无 security-scoped bookmark，Open Recent 跨 App 重启必然失败（仅日志） | **B** | PM-01、DS-04、IA 抽查⑤ | 新发现 | `PaperMD.entitlements`；`AppDelegate.swift` L333-340；全源码无 bookmark API |
| PL-03 | 沙盒下在「仅授权单文件」的同级目录创建 `{doc}.assets/` 可能被拒，静默不插图【运行时行为未知】 | **C** | PM-02、UF-05 前置 | 新发现（静态可证的授权缺口） | `ImageHandler.swift` L131-138；entitlements 仅 user-selected.read-write |
| PL-04 | Info.plist 声明 NSSupportsSuddenTermination/AutomaticTermination=true，与 3 秒自定义自动保存组合存在 <3s 编辑丢失窗口；Automatic 与「关窗驻留」张力 | **C** | UF-08 | 新发现（逆向报告未登记） | `Supporting Files/Info.plist`；`Document.swift` L188-206 |
| PL-05 | 文件被外部程序修改后无任何检测，3 秒 autosave 静默覆盖外部修改 | **B** | UF-03、DS-07 | 新发现（全源码无 NSFileVersion/文件修改日期检查） | `Document.swift` L144-177；grep 证实无冲突检测 |
| PL-06 | 查找面板每次 ⌘F 重建：查询词丢失、旧面板窗口泄漏、且打开状态下切换文档窗口后仍作用于旧目标 | **B** | UF-06、IA-02、DS-05、ST 面板态 | 新发现（P4 未立案「面板重建」——F-02/B2 为菜单联动、F-06/B6 为计数/Esc，均未涉及；本评审据跨窗口错位定为 B） | `AppDelegate.swift` L359-368；`SearchReplaceController.swift` L15、L27 |
| PL-07 | 导出/查找命令隐含「keyWindow 必须是编辑窗口」前置，偏好/查找面板聚焦时静默无响应 | **B** | IA-01、UF-五要素 | 新发现（归入静默失败族但根因不同：路由而非 IO） | `AppDelegate.swift` L359-361、L377-381、L403-405 |
| PL-08 | 首存图片迁移：moveItem 失败仍改写正文路径并无条件删除临时目录，图片文件丢失+引用坏链 | **B** | UF-05、DS-01 | 新发现 | `ImageHandler.swift` L39-61（L46 `try?`、L61 无条件 removeItem） |
| PL-09 | 未保存（untitled）文档无自动保存、无崩溃恢复，3 秒 Timer 明确 guard fileURL；崩溃即全丢 | **B** | UF-01、DS-06 | 新发现 | `Document.swift` L194（guard fileURL）；无 AutosaveInformation 使用 |
| PL-10 | PDF 导出经 WKWebView 加载远程图片被 network.client=false 拦截，静默缺图 | **C** | UF-07、PM-03 | 新发现 | `PaperMD.entitlements`；`ExportHelper.swift` L40-46 |
| PL-11 | autosavesInPlace 类属性恒 true 与偏好开关脱钩，系统层标准自动保存与自定义 Timer 双机制并存，偏好关闭时行为【未知】 | **C** | ST-03、PM-04 | 新发现 | `Document.swift` L45、L42-44 注释 |
| PL-12 | 无只读文档态：文件只读/权限丢失时仍以可编辑态打开，保存时才报错 | **C** | ST-02 | 新发现（page-spec 特检矩阵未覆盖该态） | `Document.swift`（无只读处理）；`Info.plist` |
| PL-13 | stopAutosaveTimer() 为死代码，文档关闭后计时器不显式停止（weak self 守卫下风险低） | **D** | ST-04 | 新发现（小） | `Document.swift` L208-211（grep 证实无调用） |
| PL-14 | 未保存文档关闭（选「不保存」）后 tmp/PaperMD-{UUID}.assets 残留不清理 | **D** | DS-02 | 新发现 | `ImageHandler.swift` L145-149；无关闭清理钩子 |
| PL-15 | 产品说明 5.1.1「最近打开最多 10 个」与系统托管实现矛盾（逆向死链表已登记但 P4 未勘误） | **A** | DS-04 注 | **建议勘误**（本次不执行，遵守只建 6 文件铁律） | `docs/产品说明.md` 5.1.1；`AppDelegate.swift` L307-331 |
| PL-16 | 重启后无会话/现场恢复（窗口恢复禁用+无 Recent 可达性），「回到现场」成本全在用户 | **D** | DS-09 | 与 PL-02 叠加的观察项 | `Info.plist` NSDisableWindowRestoration；`Document.swift` L39-40 |

统计：A=1、B=7、C=5、D=3，合计 **16 项**。

与 P4 评审的关系汇总：

- **升级**：PL-01（L-03/B5 的后果评级应上调——非「空文档」而是「欢迎文本文档」直接构成覆盖写回路径）。
- **新发现**：PL-02/03/04/05/06/07/08/09/10/11/12/13/14/16（14 项）。其中 PL-06 的「面板每次 ⌘F 重建」问题 P4 未立案（F-02/B2 为菜单联动、F-06/B6 为计数/Esc，均未涉及重建），本评审据查询词丢失与跨窗口错位新立为 B。
- **重复确认不另立案**：P4 B1-B8、C1-C7、D1-D7、A2 各项源码复核属实，维持原处置。

---

## 十二、建议处理优先级（供决策，非执行）

1. **第一优先（数据安全，建议全部进 V1 重构范围）**：PL-01、PL-08、PL-09、PL-05——四条路径的共同修法方向：打开/保存/迁移前校验失败即中止并给可见反馈；untitled 文档纳入标准 NSDocument autosave（AutosaveInformation）；保存前做磁盘版本检查。
2. **第二优先（可达性与一致性）**：PL-02（bookmark entitlement + 打开失败可见反馈）、PL-06（面板单例化+目标随 keyWindow 重绑）、PL-07（命令路由不依赖 keyWindow 类型）。
3. **待用户决策（C 类，逐项确认）**：PL-03（assets 目录授权策略，先实测）、PL-04（终止声明取舍）、PL-10（PDF 远程图策略）、PL-11（自动保存机制归一）、PL-12（是否支持只读态）。
4. **观察不动（D 类）**：PL-13、PL-14、PL-16。
5. **文档勘误（A 类，待授权执行）**：PL-15。

阻塞说明：本评审未受阻塞；PL-03 的最终定级依赖沙盒运行时实测（静态评审无法确证），建议列入 V1 前置验证清单。
