# PaperMD 信息架构评审

> 评审依据：《AI 产品重构逻辑评审规范 v1.0》 · 2026-09-03
> 输入文档清单：
> 1. `docs/01_reverse/REVERSE_ANALYSIS.md`（③ 页面清单表 PAGE001-014、④ 页面详细分析）
> 2. `docs/02_product/PRD.md`（§6 页面需求）
> 3. `docs/02_product/PAGE_SPEC.md`（一、全局交互约定；二、页面 11 维度规格）
> 4. `docs/06_review/PRODUCT_REVIEW.md`（P4 §二 页面问题 P-01…P-05，交叉引用）
> 5. 源码抽查：`PaperMD/App/AppDelegate.swift`、`Document.swift`、`WindowController.swift`、`EditorView.swift`、`OutlineView.swift`、`SearchReplaceController.swift`、`PreferencesWindowController.swift`
>
> 本文件为逻辑评审产出之一（IA- 编号问题清单），不修改任何现有文件。

---

## 一、导航层级图（现状，按源码绘制）

```text
系统菜单栏（常驻，PAGE002）
├── PaperMD ─ About(PAGE014) / Preferences…(PAGE008)
├── File ─ New(→新 PAGE001) / Open…(PAGE010) / Open Recent(→已存 PAGE001)
│         └ Export ─ HTML(PAGE012) / PDF(PAGE013)
├── Edit ─ Find…(PAGE009)；⌘G/⇧⌘G/⌥⌘F → 系统 find 动作（未入 PAGE009，P4 B2）
├── View ─ Toggle Sidebar / Toggle Focus Mode（PAGE001 内部状态，无新页面）
├── Format / Window / Help
│
主编辑窗口（PAGE001，一文档一窗口）
├── 工具栏（PAGE006，命令同源 PAGE002，无独立跳转）
├── 大纲侧栏（PAGE003，窗口内导航：行 → 编辑区行定位，不出窗口）
├── 编辑区（PAGE004，无跳转出）
├── 状态栏（PAGE005，纯展示）
└── 窗口状态变体：专注模式（PAGE007，无跳转）

独立面板（与主窗口平级，非 sheet、非模态）
├── 偏好设置（PAGE008，⌘， 单例）
└── 查找替换（PAGE009，⌘F，名义单例实际每次重建 → IA-02）

系统面板（按需弹出）
├── 打开（PAGE010）/ 保存另存（PAGE011）/ 导出 HTML（PAGE012）
├── 打印即 PDF（PAGE013）
└── 关于（PAGE014）
```

层级深度评价：**两层**（菜单/面板 → 主窗口），符合文档编辑器类目惯例；无超过两层的钻取。大纲、专注模式均控制在主窗口内部，未抬高层级。

---

## 二、逐窗口/面板分类归属表

分类维度按规范：容器 / 内容视图 / 状态变体 / 工具面板 / 系统中介面板。

| 编号 | 页面 | 分类归属 | 存在理由（一句话） | 归属是否恰当 | 依据 |
|------|------|----------|--------------------|:---:|------|
| PAGE001 | 主编辑窗口 | 容器（文档级） | 单文档编辑完整容器，文件即文档 | ✔ | `Document.swift` L54-94 |
| PAGE002 | 应用菜单栏 | 命令层（App 级） | 全量命令入口、全键盘可达 | ✔ | `AppDelegate.swift` L89-305 |
| PAGE003 | 大纲侧栏 | 内容视图（导航型） | 标题结构导航 | ✔ | `OutlineView.swift` |
| PAGE004 | Markdown 编辑区 | 内容视图（主工作区） | P0 输入体验载体 | ✔ | `EditorView.swift`、`MarkdownTextView.swift` |
| PAGE005 | 状态栏 | 内容视图（反馈型） | 写作统计 | ✔（位置见 P4 D3，交叉引用） | `StatusBar.swift`、`EditorView.swift` L157-166 |
| PAGE006 | 工具栏 | 命令层（窗口级） | 高频格式化一键化 | ✔（与 PAGE002 双入口属惯例） | `WindowController.swift` L58-195 |
| PAGE007 | 专注模式 | 状态变体（非独立页面） | 免打扰 | ✔（作为 PAGE001 变体建模准确） | `EditorView.swift` L358-381 |
| PAGE008 | 偏好设置 | 工具面板（App 级） | 全局偏好管理 | ✔ | `PreferencesWindowController.swift` |
| PAGE009 | 查找替换 | 工具面板（文档级） | 文档内检索替换 | **△ 归类为文档级面板，但实现为自由窗口且目标绑定不随窗口重绑（IA-02）** | `SearchReplaceController.swift` L15-30 |
| PAGE010 | 打开面板 | 系统中介面板 | 文件选择（沙盒授权点） | ✔ | `AppDelegate.swift` L124；系统 NSOpenPanel |
| PAGE011 | 保存/另存 | 系统中介面板 | 落盘 | ✔ | `Document.swift` L213-238 |
| PAGE012 | 导出 HTML | 系统中介面板 | HTML 交付 | ✔（入口路由见 IA-01） | `AppDelegate.swift` L377-401 |
| PAGE013 | 导出 PDF | 系统中介面板 | PDF 交付 | ✔（同上） | `AppDelegate.swift` L403-411 |
| PAGE014 | 关于 | 系统中介面板 | 应用信息 | ✔ | `AppDelegate.swift` L103 |

结论：**无可删除、无可合并、无可拆分的页面**；唯一归属争议是 PAGE009 的「文档级面板」语义未在实现中贯彻（目标 textView 固定于创建时刻，见 IA-02）。

---

## 三、信息架构合理性走查（§7）

1. **命令按域分组**：File/Edit/View/Format 划分与 macOS HIG 一致；查找族在 Edit、视图切换在 View、格式化在 Format，无跨域错置。唯一双义：⌥⌘C 同键分属 Edit>Transformations 与 Format>Code Block（P4 C4 交叉引用，不重复立案）。
2. **入口-能力覆盖**：高亮支持 H1-H6 而命令入口止步 H3（P4 B1/F-01 交叉引用）；预览无入口（P4 C1 交叉引用）。
3. **同源双入口一致性**：工具栏与菜单动作最终都转发 EditorView 同一方法（`WindowController.swift` L213-259），无双入口行为漂移（页面层）。
4. **命名可预期**：页面标题均使用系统/行业惯例词（Preferences/Find and Replace/Export to HTML）。

---

## 四、可预测性抽查（≥5 例，实测源码推演）

| # | 用户操作 | 用户预期 | 实际行为（证据） | 可预测性 |
|---|----------|----------|------------------|----------|
| ① | 无选区按 ⌘B | 命令禁用或无效果 | 菜单/工具栏禁用（`EditorView.swift` L463-472） | ✔ 可预测 |
| ② | 大纲点击某标题 | 跳转并定位该行 | 选中行滚动可见，0.1s 后光标收缩行首（`OutlineView.swift` L137-141、`EditorView.swift` L332-356） | ✔ 可预测 |
| ③ | 打开非 UTF-8 文件 | 报错或正确显示 | **加载欢迎文本的「伪文档」且绑定原文件路径，首次编辑 3 秒后被覆盖写回**（`Document.swift` L80-84、L167） | ✗✗ 严重不可预测（PL-01/UF-02） |
| ④ | ⌘F 后按 Esc 再按 ⌘G | 续搜上一查询 | 走系统 find 动作，与自研面板无关（`AppDelegate.swift` L180-185 未设 actionTag；P4 B2 交叉引用） | ✗ 不可预测 |
| ⑤ | 重启 App 后点 Open Recent 某项 | 打开该文件 | **沙盒拒绝访问，仅日志，用户无感知**（`AppDelegate.swift` L333-340 + entitlements 无书签，PL-02/PM-01） | ✗ 不可预测 |
| ⑥ | 偏好窗口置顶时按 ⌃⌘E | 导出当前文档 | 静默无响应（guard keyWindow contentView is EditorView 失败即 return，`AppDelegate.swift` L377-381） | ✗ 不可预测（IA-01/PL-07） |
| ⑦ | 查找面板开着，切到另一文档窗口点 Find Next | 作用于当前窗口文档 | **作用于面板创建时的旧窗口文档**（`SearchReplaceController.swift` L27 目标仅在 init 绑定） | ✗ 不可预测（IA-02/PL-06） |
| ⑧ | 专注模式中按 ⌃⌘O | 无副作用或退出专注 | 侧栏在专注态下展开形成混合态（`EditorView.swift` L385-395 独立于 focusMode；P4 D5 交叉引用） | △ 已立案观察 |
| ⑨ | 新文档直接 ⌘S | 弹保存面板默认名 | untitled.md 默认名（`Document.swift` L226-235） | ✔ 可预测 |
| ⑩ | 查找面板按 Esc | 关闭面板 | 【未知】窗口无 cancel 按钮，默认行为未在代码定义（P4 F-06 已标注未知，交叉引用） | ? 未知 |

小结：10 例中 3 例 ✔、5 例 ✗、1 例 △、1 例 ？。不可预测项集中于**面板生命周期**（⑦）与**命令路由前置**（⑥），而非页面结构本身。

---

## 五、问题清单（IA-01…）

### IA-01 全局命令隐含「keyWindow=编辑窗口」前置，失败静默无响应【B → PL-07】

- **当前设计**：`exportToHTML`/`exportToPDF`/`showSearchReplace` 均以 `NSApp.keyWindow` 且 `contentView is EditorView` 为守卫，失败即 return（`AppDelegate.swift` L359-361、L377-381、L403-405）。exportToHTML 另取 `currentDocument` 仅用于默认文件名（L378-386）。
- **问题**：命令的可达性取决于「哪个窗口恰好是 key」，而非「是否存在可操作文档」。偏好/查找面板聚焦时 ⌃⌘E/⌃⌘P/⌘F 均无任何反馈；信息架构上未定义「文档级命令在非文档窗口聚焦时」的路由规则。
- **影响**：用户在偏好窗口改完设置直接导出 → 无反应 → 误判功能损坏；属静默失败族中唯一非 IO 根因的条目。
- **建议方向**：重写期将文档级命令统一路由到「当前活动文档」（NSDocumentController.currentDocument 或最近 key 编辑窗口），并在无可用文档时禁用菜单项（灰显）而非静默返回。

### IA-02 查找面板（PAGE009）与文档窗口的从属关系未定义【B → PL-06】

- **当前设计**：PAGE009 为独立自由窗口（`SearchReplaceController.swift` L18-25，非 sheet 非模态）；目标 `targetTextView` 仅在构造时绑定一次（L27），且 `AppDelegate.showSearchReplace` 每次 ⌘F 都重建 controller（`AppDelegate.swift` L359-368，if/else 两分支均 new）。
- **问题**：文档级面板却无文档从属语义：(a) 多文档窗口切换后，面板仍作用于旧窗口文本（见抽查⑦）；(b) 每次 ⌘F 重建导致查询词/正则开关状态丢失；(c) 旧面板窗口对象泄漏。
- **影响**：多窗口写作场景（内容创作者开多稿对照）出现「在 B 窗口按 Find Next 却改了 A 窗口」的跨文档错位；重复查找的输入成本翻倍。
- **建议方向**：重写期将查找面板改为「随 key 编辑窗口重绑目标的单例面板」（page-spec 语义即此），或降级为窗口内 sheet/附条；与 P4 B2（菜单联动）同批落地。

### IA-03 状态栏（PAGE005）顶部布局与「状态反馈」心智模型的偏差【D，交叉引用 P4 D3】

- **当前设计**：`statusBarFrame` 布局于 `bounds.height-28`（AppKit 坐标视觉顶部，`EditorView.swift` L157-162）。
- **问题/影响/建议方向**：与 P4 P-04/D3 结论一致（自洽、专注模式可隐藏、观察不动），本册不重复立案，仅保留归属表记录。

### 交叉引用表（本册不重复计数）

| 本册走查点 | P4 既有编号 | 处置 |
|------------|-------------|------|
| ⌘G/⇧⌘G/⌥⌘F 未联动自研面板（抽查④） | F-02/L-01 → B2 | 维持 B2 |
| 工具栏 Heading 恒 H1（图标语义 vs 行为） | F-01/P-01 → B1 | 维持 B1 |
| ⌥⌘C 双义（§三.1） | C4 | 维持 C |
| 专注×侧栏混合态（抽查⑧） | L-05 → D5 | 维持 D5 |
| Esc 关闭查找面板（抽查⑩） | F-06 → B6（含未知标注） | 维持 B6 |
| 偏好标题 Preferences vs Settings | P-03 → D2 | 维持 D2 |

---

## 六、结论

1. 信息架构骨架（两层导航、14 页面、系统面板复用）**合理，无结构性增删需求**——与 P4 P-05「职责单一」结论互相印证。
2. 本次新增的两个 B 级问题（IA-01 命令路由、IA-02 面板从属）都属「架构语义未贯彻到实现」，重写期修复成本低、收益直接（消除 3 例不可预测交互）。
3. 可预测性短板的根因不在页面结构，而在**失败路径的可见性**（与 UF 分册异常分支结论一致）。
