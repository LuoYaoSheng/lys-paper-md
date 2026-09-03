# PaperMD 权限评审

> 评审依据：《AI 产品重构逻辑评审规范 v1.0》 · 2026-09-03
> 输入文档清单：
> 1. `docs/01_reverse/REVERSE_ANALYSIS.md`（①1.2 沙盒描述、⑧ 外部依赖）
> 2. `docs/02_product/PAGE_SPEC.md`（三、六项特检矩阵「④权限（文件访问）」列）
> 3. `docs/02_product/PRD.md`（§6 PAGE010「沙盒内用户授权目录」）
> 4. `docs/06_review/PRODUCT_REVIEW.md`（P4 交叉引用：B5 静默失败族）
> 5. 源码抽查：`PaperMD/Supporting Files/PaperMD.entitlements`、`Supporting Files/Info.plist`、`PaperMD/App/AppDelegate.swift`、`Document.swift`、`ImageHandler.swift`、`ExportHelper.swift`、`PreferencesWindowController.swift`；全源码 grep `bookmark|SecurityScoped|startAccessing` 零命中
>
> 本文件为逻辑评审产出之一（PM- 编号问题清单），不修改任何现有文件。

---

## 一、权限清单（当前实现，逐项有据）

| # | 权限项 | 声明/实现（证据） | 用途 | 最小化判定 |
|---|--------|-------------------|------|:---:|
| 1 | App Sandbox | `com.apple.security.app-sandbox=true`（`PaperMD.entitlements`） | 沙盒隔离 | ✔ |
| 2 | 用户选择文件读写 | `com.apple.security.files.user-selected.read-write=true`（同上） | ⌘O/⌘S/导出面板授权的文件 | ✔ |
| 3 | 安全作用域书签（跨启动记忆授权） | **未声明**（entitlements 无 `files.bookmarks.approved`；全源码无 bookmark API） | — | **缺失，见 PM-01** |
| 4 | 网络客户端 | `com.apple.security.network.client=false`（显式关闭） | 无联网需求（WKWebView 加载本地 HTML 字符串） | ✔（副作用见 PM-03） |
| 5 | 网络服务端 | 未声明（默认拒绝） | — | ✔ |
| 6 | 临时目录读写 | 沙盒容器自带 `tmp/`（`ImageHandler.swift` L145-152 使用 temporaryDirectory） | 未保存文档的 pending 图片 | ✔ |
| 7 | 用户偏好读写 | UserDefaults（沙盒容器内，`PreferencesWindowController.swift` L239-269） | 3 个偏好键 | ✔ |
| 8 | 文档同级目录创建（assets） | 无独立声明，依附于 #2 的授权粒度（`ImageHandler.swift` L131-138 在 documentURL 同目录 createDirectory） | 图片资产目录 | **风险见 PM-02** |
| 9 | 拖拽/粘贴读取任意文件路径 | `MarkdownTextView.swift` L344-354 对拖入 fileURL 直接 `NSImage(contentsOf:)` | 拖图插入 | ✔（沙盒天然限定可读范围；不可读时静默走默认分支，已归 B5 观察族） |
| 10 | 打印（PDF 导出） | 系统打印面板（`ExportHelper.swift` L52-61） | 「存储为 PDF」由系统代理写出 | ✔（写出位置由系统面板授权） |
| 11 | 剪贴板 | 系统默认能力（`MarkdownTextView.swift` L102-122） | 纯文本/图片粘贴 | ✔ |

**结论（总）**：权限模型符合最小化原则——除用户显式选择的文件与自身容器外无任何越界能力；无通讯录/位置/摄像头/辅助功能/全盘访问等无关声明。问题不在「多给」，而在「少配」：两个功能可达性缺口（PM-01 已确证、PM-02 待实测）与一个显式禁用带来的交付缺口（PM-03）。

---

## 二、文件访问授权与生命周期推演（沙盒语义）

1. **会话内**：用户经 NSOpenPanel/NSSavePanel 授权的路径，本次进程生命周期内可读写 —— 覆盖「打开→编辑→3 秒 autosave→保存」全链路 ✔（autosave 写已授权路径，无需额外交互，符合「自动保存权限」的预期形态）。
2. **跨启动**：无书签 → 授权不延续 —— Recent 列表中的 URL 仅是「路径字符串」，无访问权（PM-01）。
3. **同目录扩展**：授权对象是「所选文件」而非「所在目录」——在文档旁新建 `{doc}.assets/` 目录属于授权边界外动作，系统是否放行取决于 powerbox 授权粒度【运行时行为未知，需实测】（PM-02）。
4. **只读场景**：文件只读/授权丢失（外接盘拔出等）时的打开态未定义（ST-02 交叉引用）。

---

## 三、问题清单（PM-01…）

### PM-01 无安全作用域书签：Open Recent 跨 App 重启必然失败，且失败仅日志【B → PL-02】

- **当前设计**：
  - entitlements 仅有 `app-sandbox` + `user-selected.read-write` + `network.client=false` 三个键（`PaperMD.entitlements` 全文）；
  - 最近文档打开：`NSDocumentController.shared.openDocument(withContentsOf:display:)`，error 分支仅 `DebugLog.log`（`AppDelegate.swift` L333-340）；
  - 全源码 grep `bookmark|SecurityScoped|startAccessing` 零命中。
- **问题**：沙盒授权仅会话有效，而「最近文件」功能的数据（recentDocumentURLs）是跨会话持久的——两者生命周期错配，导致 Recent 子菜单在每次重启后变成「看得见、打不开」的列表；失败还是静默的（B5 第 6 点的权限根因）。
- **影响**：核心导航入口（PAGE010 的 Recent 通道）在沙盒分发形态下功能性失效；每次回到工作现场都要重新 ⌘O 浏览定位（与 PL-16 叠加）。逆向报告与 P4 均未从权限角度立案（P4 只记了「最近文档失效仅日志」的表象）。
- **建议方向**：重写期声明 `com.apple.security.files.bookmarks.approved`，在保存/打开成功时创建并解析安全作用域书签；打开失败给可见反馈（该文件已不可访问/已被移动）。

### PM-02 沙盒下创建文档同级 `.assets/` 目录的授权可达性未验证【C → PL-03】

- **当前设计**：`resolveAssetsFolder` 对已保存文档直接在 `documentURL` 同目录 `createDirectory`（`ImageHandler.swift` L131-138）；失败被 `try?` 吞掉后返回的 assetsURL 仍被用于拼文件路径，随后 `data.write` 失败才走「不插入+日志」分支（L120-128）。
- **问题**：授权模型授予的是「用户选择的文件」而非其所在目录；在目录未被授权的场景（典型的：通过 ⌘O 打开的单文件）创建同级新目录是否被沙盒放行，属 powerbox 粒度实现细节，**静态评审无法确证，标【未知】**。若被拒，用户侧表现即「粘贴图片没反应」（静默）。
- **影响**：场景 4（粘贴图片自动落盘，PRD.md P0 级）在部分授权形态下可能不可用且无反馈；page-spec 特检矩阵 PAGE004「④权限」仅写「拖入需可读文件」，未覆盖此目录创建风险。
- **建议方向**：列入 V1 前置实测清单（沙盒构建 + ⌘O 单文件授权 + 粘贴图片）；若确证受限，二选一：引导用户授权目录（open panel 目录模式/书签）或回退「图片存入容器内库+导出时打包」。实测前不定级升级。

### PM-03 network.client=false 使 PDF 导出对远程图片静默缺图【C → PL-10】

- **当前设计**：entitlements 显式 `com.apple.security.network.client=false`；PDF 通道 = WKWebView `loadHTMLString(html, baseURL: nil)`（`ExportHelper.swift` L45）——正文含 `![](http://…)` 时远程请求被禁，图片不渲染且无提示；HTML 导出为纯文本引用不受影响。
- **问题**：同一份文档经两条导出通道产出不一致（HTML 引用在、PDF 图缺失），且无任何状态反馈；「导出可靠」（P1 目标）在含远程图文档上不成立。
- **影响**：交付物质量缺陷 + 用户排障困难（归因到渲染 bug 而非网络策略）。
- **建议方向**：用户决策二选一：(a) 导出前扫描远程引用并提示「N 张远程图将被跳过」（保持离线安全的最小权限）；(b) 为导出通道单独启用网络（entitlement 变更，放弃严格离线）。默认建议 (a)。

### PM-04 「自动保存权限」的机制归口：偏好开关只控制自定义 Timer，类属性恒 true【C → PL-11】

- **当前设计**：`Document.swift` L45 `autosavesInPlace` 类属性恒 true；偏好 `autosaveEnabled` 仅在 L174-176、L183-185 两处 guard 中被自定义 3 秒 Timer 读取。
- **问题**：用户关掉「Automatically save documents」后，NSDocument 系统层的标准自动保存触发点（如某些窗口/应用生命周期时机）是否仍会落盘【未知——双机制组合行为无法静态确证】；「自动保存权限」的语义被拆在两处（系统类属性 vs 用户偏好）。
- **影响**：偏好开关的可信度存疑；与 ST-03 同源。
- **建议方向**：机制归一（详见 STATE_REVIEW.md ST-03），并补一条验收：偏好关闭时任何路径都不落盘。

---

## 四、无问题项的结论与依据

| 检查项 | 结论 | 依据 |
|--------|------|------|
| 沙盒最小化 | 无越权声明 | `PaperMD.entitlements` 全文仅 3 键 |
| 自动保存写入范围 | 仅写用户已授权的 fileURL，不越界 | `Document.swift` L194 guard + writeSafely |
| 偏好数据隔离 | 沙盒容器 UserDefaults，无需额外权限 | `PreferencesWindowController.swift` L243-268 |
| 临时文件写入 | 容器 tmp，无权限交互 | `ImageHandler.swift` L145-152 |
| 剪贴板/拖拽 | 系统默认能力，无隐私敏感读取 | `MarkdownTextView.swift` L102-122、L340-365 |
| 打印面板写出 | 系统代理的 powerbox 交互 | `ExportHelper.swift` L52-61 |
| 网络服务端/其他系统权限 | 未声明，默认拒绝 | entitlements 无相关键 |

---

## 五、本册问题汇总

| 编号 | 标题 | 分级 | 映射 PL | 与 P4 关系 |
|------|------|:---:|:---:|------------|
| PM-01 | 无书签 entitlement → Recent 跨启动失效（静默） | B | PL-02 | 新发现（P4 仅记表象 B5-6） |
| PM-02 | 同级 .assets/ 目录创建的沙盒可达性未验证【未知】 | C | PL-03 | 新发现 |
| PM-03 | 网络禁令 → PDF 远程图片静默缺图 | C | PL-10 | 新发现 |
| PM-04 | 自动保存机制归口分裂（类属性 vs 偏好） | C | PL-11 | 新发现 |
