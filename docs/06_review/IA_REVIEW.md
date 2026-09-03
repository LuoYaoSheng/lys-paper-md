# PaperMD 信息架构评审综合（IA_REVIEW）

> 版本：v1.0　日期：2026-09-03
> 综合输入：`docs/product-review/INFORMATION_ARCHITECTURE_REVIEW.md`（信息架构评审，2026-09-03——导航层级/分类归属/合理性走查/可预测性抽查/IA 问题清单）
> 关联输入（交叉引用用）：`docs/06_review/PRODUCT_REVIEW.md`（P4 §二 页面问题）、`docs/02_product/PAGE_SPEC.md`、`docs/01_reverse/REVERSE_ANALYSIS.md` ③④
> 说明：本文件为 IA 分册的综合视图登记（SOP 06_review 交付物），完整论证以其原文为准；本文不新增事实。

---

## 1. 架构骨架结论

- **两层导航**（系统菜单栏/面板 → 主编辑窗口），符合文档编辑器类目惯例；无超过两层的钻取；大纲、专注模式均控制在主窗口内部。
- 14 页面（PAGE001-014）经逐项分类归属走查：**无可删除、无可合并、无可拆分**；与 P4 P-05「职责单一」结论互相印证。
- 分类维度：容器（文档级/App 级命令层）/ 内容视图（导航型/主工作区/反馈型）/ 状态变体 / 工具面板（App 级/文档级）/ 系统中介面板。唯一归属争议：PAGE009 查找面板被归类为「文档级面板」，但实现为自由窗口且目标绑定不随窗口重绑（IA-02）。
- 跳转关系图与出入口表已沉淀至 `docs/03_flow/PAGE_FLOW.md`。

（源：INFORMATION_ARCHITECTURE_REVIEW.md §一/§二/§六）

## 2. 合理性走查四要点

1. **命令按域分组**：File/Edit/View/Format 划分与 macOS HIG 一致，无跨域错置；唯一双义 ⌥⌘C 同键分属 Edit>Transformations 与 Format>Code Block（P4 C4，不重复立案）。
2. **入口-能力覆盖**：高亮支持 H1-H6 而命令入口止步 H3（P4 B1/F-01）；预览无入口（P4 C1）。
3. **同源双入口一致性**：工具栏与菜单动作最终都转发 EditorView 同一方法（`WindowController.swift` L213-259），无双入口行为漂移。
4. **命名可预期**：页面标题均使用系统/行业惯例词（Preferences/Find and Replace/Export to HTML）。

（源：同上 §三）

## 3. 可预测性抽查结果（10 例）

| 结果 | 数量 | 条目 |
|------|:----:|------|
| ✔ 可预测 | 3 | ①无选区 ⌘B 禁用；②大纲点击定位；⑨新文档 ⌘S 默认名 |
| ✗ 不可预测 | 5 | ③打开非 UTF-8→伪文档+覆盖链（UF-02）；④Esc 后 ⌘G 走系统动作；⑤Recent 跨重启静默失败（PM-01）；⑥偏好窗置顶 ⌃⌘E 无响应（IA-01）；⑦查找面板作用于旧窗口（IA-02） |
| △ 观察项 | 1 | ⑧专注×侧栏混合态（P4 D5） |
| ? 未知 | 1 | ⑩查找面板 Esc 行为未定义（P4 F-06/B6） |

**小结**（源：同上 §四）：不可预测项集中于**面板生命周期**（⑦）与**命令路由前置**（⑥），而非页面结构本身；根因是**失败路径的可见性**（与 UF 分册异常分支结论一致）。

## 4. 问题清单（IA-01…）

### IA-01 全局命令隐含「keyWindow=编辑窗口」前置，失败静默无响应【B → PL-07】

- 事实：exportToHTML / exportToPDF / showSearchReplace 均以 `NSApp.keyWindow` 且 `contentView is EditorView` 为守卫，失败即 return（`AppDelegate.swift` L359-361、L377-381、L403-405）。
- 影响：命令可达性取决于「哪个窗口恰好是 key」而非「是否存在可操作文档」；偏好/查找面板聚焦时 ⌃⌘E/⌃⌘P/⌘F 无任何反馈——静默失败族中唯一非 IO 根因条目。
- 方向：统一路由到当前活动文档（NSDocumentController.currentDocument 或最近 key 编辑窗口）；无可用文档时菜单灰显而非静默返回。

### IA-02 查找面板（PAGE009）与文档窗口的从属关系未定义【B → PL-06】

- 事实：PAGE009 为独立自由窗口（非 sheet 非模态）；目标 targetTextView 仅构造时绑定一次（`SearchReplaceController.swift` L27）；每次 ⌘F 重建 controller（`AppDelegate.swift` L359-368 if/else 双 new）。
- 影响：(a) 跨窗口错位——B 窗口按 Find Next 改了 A 窗口文本（与 UF-06 同源）；(b) 查询词/正则状态丢失；(c) 旧面板对象泄漏。
- 方向：随 key 编辑窗口重绑目标的单例面板，或降级为窗口内 sheet/附条；与 P4 B2 同批。

### IA-03 状态栏顶部布局【D，交叉引用 P4 D3】

与 P4 P-04/D3 结论一致（自洽、专注模式可隐藏、观察不动），本册不重复立案。

（源：INFORMATION_ARCHITECTURE_REVIEW.md §五）

## 5. 交叉引用表（本册不重复计数）

| 走查点 | P4 既有编号 | 处置 |
|--------|-------------|------|
| ⌘G/⇧⌘G/⌥⌘F 未联动自研面板 | F-02/L-01 → B2 | 维持 B2 |
| 工具栏 Heading 恒 H1 | F-01/P-01 → B1 | 维持 B1 |
| ⌥⌘C 双义 | C4 | 维持 C |
| 专注×侧栏混合态 | L-05 → D5 | 维持 D5 |
| Esc 关闭查找面板 | F-06 → B6（含未知标注） | 维持 B6 |
| 偏好标题 Preferences vs Settings | P-03 → D2 | 维持 D2 |

## 6. 综合结论

1. 信息架构骨架合理（两层导航、14 页面、系统面板复用），**无结构性增删需求**——重构为「照旧复刻」型，不做导航改版。
2. 两个 B 级问题（IA-01 命令路由、IA-02 面板从属）都属「架构语义未贯彻到实现」，重写期修复成本低、收益直接（消除 3 例不可预测交互：抽查④⑥⑦）。
3. 可预测性短板根因不在页面结构，而在**失败路径的可见性**——与 `docs/06_review/UX_REVIEW.md` §2 结论一致；B5 反馈体系落地时 IA-01/IA-02 应同批处理。
