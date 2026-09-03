# PaperMD 重构文档总索引（DOCUMENT_INDEX）

> 版本：v1.0　日期：2026-09-03（文档体系迁移日）
> 体系：《旧 App AI 重构 SOP v2.0》编号文档体系 00_context～09_test + prototype/{v0-old,v1-new}
> 本索引只登记本 SOP 体系文件；项目自有文档（docs/ROADMAP.md、docs/UI.md、docs/TEXTKIT2_SPIKE.md、docs/index.md、docs/产品说明.md、VitePress 站点等）不在本索引管辖、保持原位不动。

---

## 1. 编号目录一览

### 00_context 项目上下文

| 文件 | 内容 | 产出 |
|------|------|------|
| `docs/00_context/PROJECT_CONTEXT.md` | 项目定位/仓库布局/构建方式（Xcode 工程结构）/关键入口 | 2026-09-03 新建 |
| `docs/00_context/TECH_STACK.md` | Swift/AppKit/TextKit 1 版本与系统能力（源：project.pbxproj、import 审计） | 2026-09-03 新建 |
| `docs/00_context/ASSET_INVENTORY.md` | 资产清单（无 .xcassets/无图标/欢迎文本模板/SF Symbols/fixture） | 2026-09-03 新建 |
| `docs/00_context/DEPENDENCY_LIST.md` | 依赖清单（已核实：App 产物零第三方依赖） | 2026-09-03 新建 |

### 01_reverse 逆向分析

| 文件 | 内容 | 产出 |
|------|------|------|
| `docs/01_reverse/REVERSE_ANALYSIS.md` | 旧项目全量逆向分析报告（①-⑨ + 测试资产登记） | 原 docs/reverse-analysis.md（2026-09-02） |

### 02_product 产品

| 文件 | 内容 | 产出 |
|------|------|------|
| `docs/02_product/PRD.md` | 产品需求文档 v1.0-rebuild（F001-F060、PAGE001-014、验收标准） | 原 docs/product/prd.md |
| `docs/02_product/PAGE_SPEC.md` | 页面级交互规格（14 页 11 维度 + 特检矩阵） | 原 docs/product/page-spec.md |
| `docs/02_product/PRODUCT_MODEL.md` | 产品定位/用户角色/使用场景/核心价值 | 2026-09-03 新建 |
| `docs/02_product/FEATURE_MAP.md` | 产品能力树（F001-F060 → G1-G10 分组） | 2026-09-03 新建 |

### 03_flow 流程

| 文件 | 内容 | 产出 |
|------|------|------|
| `docs/03_flow/USER_FLOW.md` | 用户旅程 5 组（Mermaid）+ 五要素总表 | 2026-09-03 新建 |
| `docs/03_flow/PAGE_FLOW.md` | 窗口/面板跳转关系（总图 + 出入口表 + 路由规则） | 2026-09-03 新建 |
| `docs/03_flow/BUSINESS_FLOW.md` | 正常/异常/边界流程（含 UF-02/UF-05/UF-03 已知缺陷链） | 2026-09-03 新建 |

### 04_architecture 架构

| 文件 | 内容 | 产出 |
|------|------|------|
| `docs/04_architecture/SYSTEM_ARCH.md` | 重写技术架构（分层/选型/TextKit 2 评估/机制承接） | 原 docs/architecture/tech-architecture.md |
| `docs/04_architecture/MODULE_ARCH.md` | 重写模块拆分（目标结构/公共能力归位/依赖规则） | 原 docs/architecture/module-split.md |
| `docs/04_architecture/STATE_MACHINE.md` | 重写状态管理（NSDocument/撤销栈/编辑调度状态机） | 原 docs/architecture/state-management.md |
| `docs/04_architecture/DATA_FLOW.md` | 数据流动（文本主链/写路径/图片资产流/派生流） | 2026-09-03 新建 |

### 05_sequence 时序

| 文件 | 内容 | 产出 |
|------|------|------|
| `docs/05_sequence/SEQUENCE_DIAGRAMS.md` | 6 张 sequenceDiagram（打开/自动保存/图片迁移/导出 PDF/外部修改冲突/导出 HTML） | 2026-09-03 新建 |

### 06_review 评审

| 文件 | 内容 | 产出 |
|------|------|------|
| `docs/06_review/PRODUCT_REVIEW.md` | P4 产品体验审查报告（F/P/L 问题 + 公共能力四层 + A-D 分级） | 原 docs/review/product-review.md |
| `docs/06_review/UX_REVIEW.md` | 体验评审综合（P4 × 用户流程评审 UF 归并） | 2026-09-03 新建 |
| `docs/06_review/IA_REVIEW.md` | 信息架构评审综合（IA 分册登记） | 2026-09-03 新建 |

### 07_design_system 设计系统

| 文件 | 内容 | 产出 |
|------|------|------|
| `docs/07_design_system/TOKEN.md` | 设计令牌（色板/字号/间距/尺寸常量） | 原 design-system/tokens.md |
| `docs/07_design_system/COMPONENT.md` | 组件规格（CP 层 V1 变体） | 原 design-system/components.md |
| `docs/07_design_system/PATTERN.md` | 交互模式（快捷键全集等） | 原 design-system/patterns.md |
| `docs/07_design_system/ASSETS.md` | 设计资产清单 | 原 design-system/assets.md |
| `docs/07_design_system/GUIDELINES.md` | 设计准则 | 原 design-system/guidelines.md |

### 08_development 开发

| 文件 | 内容 | 产出 |
|------|------|------|
| `docs/08_development/DATA_MODEL.md` | 重写数据模型（实体/ER/写路径） | 原 docs/architecture/data-model.md |
| `docs/08_development/API_SPEC.md` | 重写内部模块契约（进程内 protocol 层） | 原 docs/architecture/api-design.md |
| `docs/08_development/ERROR_CODE.md` | 错误处理盘点（23 处 try? + B5 七点）+ 错误码规范建议 | 2026-09-03 新建 |
| `docs/08_development/PERMISSION.md` | 权限规格（entitlements 现状 3 键 + PM-01…04 + 目标） | 2026-09-03 新建 |

### 09_test 测试验收

| 文件 | 内容 | 产出 |
|------|------|------|
| `docs/09_test/COVERAGE_CHECKLIST.md` | HTML 原型覆盖核对清单 | 原 docs/product/html-coverage-checklist.md |
| `docs/09_test/HTML_V0_ACCEPTANCE.md` | v0 旧版 HTML 原型验收报告 | 原 docs/product/html-acceptance-report.md |
| `docs/09_test/V1_ACCEPTANCE.md` | V1 新版原型验收（B1-B8 逐项核验） | 原 docs/review/v1-acceptance.md |

### prototype 原型（原位不动）

| 目录/文件 | 内容 |
|-----------|------|
| `prototype/v0-old/app-prototype.html` | v0 旧版原型（旧 App 事实复刻） |
| `prototype/v1-new/app-prototype.html` | v1 新版原型（B1-B8 修复后规格） |

### 原位登记：产品逻辑评审六件套（docs/product-review/，未迁移）

| 文件 | 内容 |
|------|------|
| `docs/product-review/PRODUCT_LOGIC_REVIEW.md` | 产品逻辑评审主册（PL 问题总表） |
| `docs/product-review/USER_FLOW_REVIEW.md` | 用户流程评审（UF-01…UF-08） |
| `docs/product-review/INFORMATION_ARCHITECTURE_REVIEW.md` | 信息架构评审（IA-01…IA-03） |
| `docs/product-review/DATA_STORAGE_REVIEW.md` | 数据与存储评审（DS 系列） |
| `docs/product-review/STATE_REVIEW.md` | 状态评审（ST 系列） |
| `docs/product-review/PERMISSION_REVIEW.md` | 权限评审（PM-01…PM-04） |

> 注意：六件套保持原位不动（2026-09-03 迁移决议），其内部引用的旧文档路径可用下方 §3 映射表换算。

## 2. 阅读顺序建议

1. 入门：`00_context/PROJECT_CONTEXT.md` → `01_reverse/REVERSE_ANALYSIS.md`
2. 产品：`02_product/PRD.md` → `02_product/PRODUCT_MODEL.md` / `FEATURE_MAP.md` → `03_flow/*`
3. 评审结论：`06_review/PRODUCT_REVIEW.md`（P4 总册）→ `06_review/UX_REVIEW.md` / `IA_REVIEW.md` → `docs/product-review/`（六分册细节）
4. 重写蓝图：`04_architecture/SYSTEM_ARCH.md` → `MODULE_ARCH.md` / `STATE_MACHINE.md` / `DATA_FLOW.md` → `05_sequence/SEQUENCE_DIAGRAMS.md` → `08_development/*`
5. 验收：`09_test/*` + `Tests/INPUT_REGRESSION_CHECKLIST.md`

## 3. 路径映射表（旧 → 新，供历史引用换算）

| 旧路径（2026-09-03 前） | 新路径 |
|--------------------------|--------|
| docs/reverse-analysis.md | docs/01_reverse/REVERSE_ANALYSIS.md |
| docs/product/prd.md | docs/02_product/PRD.md |
| docs/product/page-spec.md | docs/02_product/PAGE_SPEC.md |
| docs/product/html-coverage-checklist.md | docs/09_test/COVERAGE_CHECKLIST.md |
| docs/product/html-acceptance-report.md | docs/09_test/HTML_V0_ACCEPTANCE.md |
| docs/review/product-review.md | docs/06_review/PRODUCT_REVIEW.md |
| docs/review/v1-acceptance.md | docs/09_test/V1_ACCEPTANCE.md |
| docs/architecture/tech-architecture.md | docs/04_architecture/SYSTEM_ARCH.md |
| docs/architecture/module-split.md | docs/04_architecture/MODULE_ARCH.md |
| docs/architecture/state-management.md | docs/04_architecture/STATE_MACHINE.md |
| docs/architecture/data-model.md | docs/08_development/DATA_MODEL.md |
| docs/architecture/api-design.md | docs/08_development/API_SPEC.md |
| design-system/tokens.md | docs/07_design_system/TOKEN.md |
| design-system/components.md | docs/07_design_system/COMPONENT.md |
| design-system/patterns.md | docs/07_design_system/PATTERN.md |
| design-system/assets.md | docs/07_design_system/ASSETS.md |
| design-system/guidelines.md | docs/07_design_system/GUIDELINES.md |
| design-system/（目录引用） | docs/07_design_system/ |
| prototype/v0-old/、prototype/v1-new/ | 原位不变 |

## 4. 维护约定

- 编号目录内文件的修改遵循各自文档头的分级处置约定（P4 A/B/C/D）；A 类勘误须在 `docs/06_review/PRODUCT_REVIEW.md` §六登记。
- 项目自有文档与源码不属于本体系，任何修改须另行授权。
