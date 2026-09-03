# PaperMD 权限规格（PERMISSION）

> 版本：v1.0　日期：2026-09-03
> 事实来源：`PaperMD/Supporting Files/PaperMD.entitlements`（全文 3 键）、`PaperMD/Supporting Files/Info.plist`、`docs/product-review/PERMISSION_REVIEW.md`（权限评审，PM-01…PM-04）、`docs/06_review/PRODUCT_REVIEW.md`（P4 B5）、`docs/04_architecture/SYSTEM_ARCH.md` §5（安全）
> 说明：§1-§2 为现状（旧 App 事实）；§3 为目标规格（重写期，标注来源决议与【建议，待用户确认】项）。

---

## 1. 现状：Entitlements 全量（3 键，源文件原文）

| 键 | 值 | 用途 | 评审判定 |
|----|----|------|----------|
| `com.apple.security.app-sandbox` | true | App Sandbox 隔离 | ✔ 最小化 |
| `com.apple.security.files.user-selected.read-write` | true | ⌘O/⌘S/导出面板用户显式授权的文件读写 | ✔ 最小化 |
| `com.apple.security.network.client` | **false**（显式关闭） | 无联网需求；WKWebView 仅加载本地 HTML 字符串 | ✔（副作用见 PM-03：PDF 远程图静默缺图） |

**未声明**：安全作用域书签（`files.bookmarks.approved`）——全源码 grep `bookmark|SecurityScoped|startAccessing` 零命中（PM-01 根因）。其余系统权限（网络服务端/通讯录/位置/摄像头/辅助功能/全盘访问等）均未声明，默认拒绝。

（源：`PaperMD/Supporting Files/PaperMD.entitlements` 全文；`docs/product-review/PERMISSION_REVIEW.md` §一权限清单 11 项逐条表）

**总评**（PERMISSION_REVIEW §一）：权限模型符合最小化原则——问题不在「多给」，而在「少配」：两个可达性缺口（PM-01 已确证、PM-02 待实测）与一个显式禁用带来的交付缺口（PM-03）。

## 2. 现状：文件访问授权生命周期（沙盒语义推演）

| 场景 | 行为 | 结论 |
|------|------|------|
| 会话内（面板授权后） | NSOpenPanel/NSSavePanel 授权路径本进程生命周期内可读写——覆盖「打开→编辑→3 秒 autosave→保存」全链路 | ✔ 无需额外交互 |
| 跨启动 | 无书签 → 授权不延续；Recent 列表 URL 仅为路径字符串，无访问权 | ✘ **PM-01（B → PL-02）**：Open Recent 跨重启必然失败且仅日志 |
| 同目录扩展 | 授权对象是「所选文件」非「所在目录」；在文档旁新建 `{doc}.assets/` 属授权边界外动作，是否放行取决于 powerbox 粒度 | ? **PM-02（C → PL-03）**：【未知——静态评审无法确证，需沙盒实测】 |
| 只读/授权丢失 | 打开态未定义（外接盘拔出等） | 【未知】（ST-02 交叉引用） |

（源：PERMISSION_REVIEW §二）

### 配套 Info.plist 声明（与保存机制相关）

- `NSSupportsSuddenTermination=true` / `NSSupportsAutomaticTermination=true`：与自定义 3 秒 Timer 保存机制组合存在 <3 秒编辑丢失窗口、且与「关窗驻留」语义张力（UF-08，C 级，留档）。
- `NSDisableWindowRestoration=true`、`NSQuitAlwaysKeepsWindows=false`：窗口恢复禁用（维持）。

（源：`PaperMD/Supporting Files/Info.plist` L27-34；`docs/product-review/USER_FLOW_REVIEW.md` §七 UF-08）

### 问题清单汇总（现状 4 项）

| 编号 | 标题 | 分级 | 映射 PL |
|------|------|:---:|:---:|
| PM-01 | 无安全作用域书签 → Recent 跨启动失效（静默） | B | PL-02 |
| PM-02 | 沙盒下创建文档同级 .assets/ 目录可达性未验证【未知】 | C | PL-03 |
| PM-03 | 网络禁令 → PDF 远程图片静默缺图 | C | PL-10 |
| PM-04 | 自动保存机制归口分裂（autosavesInPlace 类属性恒 true vs 偏好开关仅控 Timer） | C | PL-11 |

（源：PERMISSION_REVIEW §五）

## 3. 目标规格（重写期）

### 3.1 Entitlements 目标形态【建议，待用户确认】

| 键 | 现值 | 目标 | 依据 |
|----|------|------|------|
| app-sandbox | true | **true（维持）** | SYSTEM_ARCH §5「App Sandbox 维持（用户选择文件读写、网络关闭）」 |
| files.user-selected.read-write | true | true（维持） | 同上 |
| `com.apple.security.files.bookmarks.approved` | 未声明 | **新增** | PM-01 处置：声明后在保存/打开成功时创建并解析安全作用域书签，打开失败给可见反馈（PMD-P01） |
| network.client | false | **默认维持 false**；若用户选 PM-03 方案 (b) 则单独评估放行 | PM-03 二选一：(a) 导出前扫描远程引用提示「N 张远程图将被跳过」（默认建议）；(b) 为导出通道单独启用网络（放弃严格离线） |

### 3.2 行为目标

1. **Recent 跨启动可达**：书签创建/解析/失效三态处理；失效 → 可见 alert（PM-01，配 `docs/08_development/ERROR_CODE.md` PMD-P01）。
2. **assets 目录创建实测前置**：V1 前置实测清单（沙盒构建 + ⌘O 单文件授权 + 粘贴图片）；若确证受限二选一：引导用户授权目录（open panel 目录模式/书签）或回退「图片存容器内库+导出时打包」（PM-02）。
3. **自动保存机制归一**：`autosavesInPlace` 类属性与偏好开关语义统一（PM-04/ST-03 同源）；补验收「偏好关闭时任何路径都不落盘」；untitled 文档纳入标准 NSDocument 自动保存体系或 UI 明示边界（UF-01）。
4. **termination 声明评估**：重写期评估移除 NSSupportsSuddenTermination/AutomaticTermination，或确认保存机制（含 untitled autosave）闭环后保留（UF-08，工程决策留用户确认）。
5. **安全底线维持**：导出 HTML 全量转义（escapeHTML）防注入；无网络面=无传输攻击面（SYSTEM_ARCH §5）。

### 3.3 验收要点（挂钩 V1 验收）

- 沙盒分发形态下：打开授权文件 → 重启 App → Open Recent 打开成功（书签生效）。
- 偏好关闭自动保存 → 任意等待时长 → 磁盘 mtime 不变。
- 含远程图文档导出 PDF → 用户收到「N 张远程图将被跳过」提示（方案 a）。
- 沙盒 + ⌘O 单文件授权 + 粘贴图片 → 图片成功落盘 `{文档名}.assets/`（PM-02 实测通过）。
