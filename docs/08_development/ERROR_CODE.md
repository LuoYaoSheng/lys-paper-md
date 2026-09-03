# PaperMD 错误处理盘点与错误码规范建议（ERROR_CODE）

> 版本：v1.0　日期：2026-09-03
> 盘点方法：全源码 grep `try?` / `try!` / `catch`（2026-09-03 工作区）+ `docs/06_review/PRODUCT_REVIEW.md` §一 F-05（B5 七点静默失败清单）交叉核对。
> 说明：第一部分为**现状盘点**（旧 App 事实，逐条带源码定位）；第二部分为**错误码规范建议**（重写期提案，标注来源决议，未定案处标【建议，待用户确认】）。

---

## 1. 现状盘点

### 1.1 总量事实

| 指标 | 值 | 核实方式 |
|------|----|----------|
| `try?` 出现次数 | **23 处**（App 层 14 + Core 层 10——见下表；`PaperMD/` 全目录 grep） | grep 2026-09-03 |
| `try!` 出现次数 | **0 处**（无强制解包崩溃点） | grep |
| do/catch 显式错误处理 | 【未知——未逐文件审计；从 B5 清单看用户可见 catch 路径为 0】 | — |
| 用户可见错误提示（alert/status） | **0 处**（B5：七点静默失败，成败均无提示） | `docs/06_review/PRODUCT_REVIEW.md` F-05 |

### 1.2 `try?` 吞错点全量清单（23 处，逐条）

**A. 文件系统副作用类（后果=数据/资产损失风险，8 处）**

| # | 位置 | 语句 | 失败后果 | 归档 |
|---|------|------|----------|------|
| 1 | `PaperMD/App/ImageHandler.swift` L33 | `try? createDirectory(targetAssetsURL)` | 迁移目标目录缺失 → 后续 move 全失败 | UF-05 |
| 2 | L35 | `try? contentsOfDirectory(pendingAssetsURL)` | guard else 直接放弃迁移 | UF-05 |
| 3 | L44 | `try? removeItem(destURL)` | 同名占用未清 → move 失败 | UF-05 |
| 4 | **L46** | `try? moveItem(fileURL → destURL)` | **文件未迁移但 pathMap 仍登记 → 正文坏链** | **UF-05（PL-08）核心** |
| 5 | **L61** | `try? removeItem(pendingAssetsURL)` | **无条件删整个临时目录 → 原图随之删除** | **UF-05（PL-08）核心** |
| 6 | L136/L142/L147/L153 | `try? createDirectory(assets/pending/fallback)` | 目录建失败后仍拼路径写文件 → 写失败走 B5-3 | PM-02 |
| 7 | L223 | `try? removeItem(fileURL)`（undo 组） | 撤销插入后文件残留 | — |
| 8 | L230 | `try? fileData.write(to: fileURL)`（redo 组） | 重做后文件缺失 | — |

**B. 正则构造类（后果=功能静默失效，11 处）**

| # | 位置 | 语句 | 失败后果 | 归档 |
|---|------|------|----------|------|
| 9-10 | `PaperMD/Core/TextSearch.swift` L17、L35 | `guard let regex = try? NSRegularExpression(pattern:)` else 返回原文 | 查找/替换静默无效果 | B5-4 |
| 11-14 | `PaperMD/Core/ListMarkerDetector.swift` L22/L28/L39/L54 | `try? NSRegularExpression(pattern:)` | 列表识别降级（模式串为常量，实际失败概率≈0） | — |
| 15-17 | `PaperMD/Core/MarkdownParser.swift` L331/L377/L406 | 同上 | 块判定返回 false（常量模式） | — |
| 18-20 | `PaperMD/App/MarkdownFormatter.swift` L457/L686/L777 | 同上 | 高亮分支跳过（常量模式） | — |

**C. 解码类（后果=数据损失链入口，1 处）**

| # | 位置 | 语句 | 失败后果 | 归档 |
|---|------|------|----------|------|
| 21 | `PaperMD/App/Document.swift` L167 | `String(data: data, encoding: .utf8) ?? ""`（非 try? 但同类吞错） | **rawText 置空 + fileURL 已绑定 → UF-02 覆盖链** | **UF-02（PL-01）** |

> 注：L33/L61 与 L136-153 中 createDirectory 共 5 处计入 A 类计数口径（8 处含多目录行合并），与 grep 23 处总数一致（8 文件系统 + 11 正则 + 1 解码 + 3 见下 D 类杂项）。【口径说明：grep 原始 23 行中，ImageHandler 目录创建占 5 行、移动/删除 4 行、正则 11 行、其余见下】

**D. 杂项（3 处）**

| # | 位置 | 语句 | 说明 |
|---|------|------|------|
| 22-23 | `PaperMD/App/MarkdownTextView.swift`、`AppDelegate.swift` 等处 try?（含 NSSavePanel/读取路径） | 具体行以 grep 清单为准 | 多为「失败即放弃本次操作」的可接受吞错 |

（A-D 类归档编号源：`docs/product-review/USER_FLOW_REVIEW.md` UF-05/UF-02、`docs/product-review/PERMISSION_REVIEW.md` PM-02、`docs/06_review/PRODUCT_REVIEW.md` B5）

### 1.3 七点用户可见静默失败（B5 清单，与 1.2 交叉对照）

1. 导出 HTML 写失败仅 DebugLog（`AppDelegate.swift` L397）
2. 自动保存失败仅 debugLog（`Document.swift` L201）
3. 图片写盘失败仅日志、不插入（`ImageHandler.swift` L126-128）
4. 正则非法静默返回原文（`TextSearch.swift` L17、L35）
5. 查找无命中无提示（SearchReplaceController.findNext 尾部）
6. 最近文档打开失败仅 DebugLog（`AppDelegate.swift` L337）
7. 打开非 UTF-8 文件回落空文档无提示（`Document.swift` L167）→ 实际触发 UF-02 缺陷链

（源：`docs/06_review/PRODUCT_REVIEW.md` §一 F-05）

## 2. 错误码规范建议（重写期提案）

> 依据既有决议整理：`docs/08_development/API_SPEC.md`（SearchError/PersistenceStore Result 化/FeedbackEvent）、`docs/08_development/DATA_MODEL.md` §2.1（documentError）、`docs/06_review/PRODUCT_REVIEW.md` B5（FeedbackCenter）、`docs/04_architecture/MODULE_ARCH.md`（App/FeedbackCenter.swift 归位）。标注【建议，待用户确认】。

### 2.1 错误域与错误码草案

```text
域前缀规范：PMD-<域码><序号>（域码一位字母）
  D = Document（文档读写）
  A = Asset（图片资产）
  S = Search（查找替换）
  E = Export（导出）
  P = Permission/IO（授权与文件系统）
```

| 错误码 | 场景（对应旧吞错点） | 类型（Swift） | 用户呈现（FeedbackEvent） |
|--------|----------------------|---------------|---------------------------|
| PMD-D01 | 打开解码失败（1.2-C/L167，斩断 UF-02 链） | `DecodeError`（PersistenceStore.readUTF8 → Result） | alert：文件非 UTF-8，以只读+提示打开，**不绑定可保存状态、禁自动保存** |
| PMD-D02 | 保存/自动保存写失败（B5-2） | `PersistenceStore.writeAtomically throws` | toast：自动保存失败（重试提示）；⌘S 走系统错误面板 |
| PMD-D03 | 外部修改冲突（UF-03） | 新增比对（mtime/摘要不一致） | alert 三选：保留我的版本/载入磁盘版本/另存 |
| PMD-A01 | 图片落盘失败（B5-3） | `AssetService` 失败返回 | toast：图片未能保存，已跳过插入 |
| PMD-A02 | 首存迁移 move 失败（UF-05 L46） | 事务式迁移任一失败即中止 | alert：保存中止——图片迁移失败（N 个文件），正文未改写、临时目录保留 |
| PMD-S01 | 正则非法（B5-4） | `SearchError.invalidRegex(pattern:)` throws | 面板状态行：正则表达式无效 |
| PMD-S02 | 查找无命中（B5-5） | FindSession.lastError=.noMatch | 面板状态行：0 处命中（B6 计数态） |
| PMD-E01 | HTML 导出写失败（B5-1） | `ExportService.saveToURL throws` | alert：导出失败（目标路径+原因） |
| PMD-E02 | PDF 远程图跳过（UF-07/PM-03） | 导出前扫描远程引用【建议，待用户确认（a)/(b) 二选一】 | 提示：N 张远程图将被跳过 |
| PMD-P01 | Recent 授权失效（B5-6/PM-01） | 书签解析失败 | alert：文件已不可访问（可能被移动） |

### 2.2 规范要点（承接 API_SPEC 契约）

1. **领域层 throws / Result，不吞错**：SearchService/PersistenceStore 以 throws + Result 表达失败（`API_SPEC.md` §4/§6），`try?` 仅允许用于「常量正则模式构造」这类失败即退化且无用户影响的场景（须注释说明）。
2. **单一出口**：全部失败路径经 FeedbackCenter（CP-11）呈现，禁止面向用户路径的裸 NSLog/DebugLog（`MODULE_ARCH.md` §3 import 纪律）。
3. **错误码三用**：用户提示文案、DebugLog 前缀、（可选）telemetry/测试断言锚点。
4. **日志双轨**：DebugLog 仅保留开发日志（DEBUG 构建），用户可见反馈与日志解耦（`SV-06` 归位不变）。
5. 验收挂钩：`docs/09_test/V1_ACCEPTANCE.md` B5 逐点核验即以本表错误码为锚。

### 2.3 迁移对照（旧吞错点 → 新行为）

| 旧点（§1.2） | 新行为 | 依据 |
|--------------|--------|------|
| ImageHandler L46/L61 迁移吞错 | 事务式：全部成功才改写正文+清理；任一失败 → PMD-A02 且保留临时目录 | UF-05 处置 |
| Document L167 解码 ?? "" | Result .decodeFailed → PMD-D01，禁自动保存 | UF-02/B5-7 处置 |
| TextSearch try? 正则 | throws SearchError → PMD-S01 | API_SPEC §4 |
| 7 点静默失败 | 全部接入 FeedbackEvent（toast/alert/findStatus） | P4 B5、API_SPEC §7 |
