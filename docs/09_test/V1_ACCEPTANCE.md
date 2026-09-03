# PaperMD V1 新版原型验收报告

> 验收人角色：测试负责人（不改产品逻辑；缺陷可修复但记录修复项）
> 验收对象：prototype/v1-new/app-prototype.html（P6 V1 新版原型，单文件交互原型）
> 对比基准：docs/02_product/PRD.md（功能全集 60 项）· docs/02_product/PAGE_SPEC.md · docs/06_review/PRODUCT_REVIEW.md（B1-B8 落地要求）· docs/07_design_system/（DS 一致性）
> 验收日期：2026-09-02　验收环境：macOS（darwin 25.5.0 arm64）· node v24.12.0 语法校验 · Playwright 浏览器实测（临时 http.server 18923 端口，测毕已关闭）

---

## 一、验收方法

1. **静态校验**：提取原型内嵌 `<script>`（1431 行）至临时文件，`node --check` → **通过**（修改后复检再次通过）。
2. **浏览器实测**：`python3 -m http.server` 起临时服务，Playwright 打开页面执行 **5 批共 67 项断言**（结构/高亮 15 项、查找替换与 B 类 12 项、菜单与窗口 12 项、文档与图片 10 项、导出/主题/五态/IME 18 项），覆盖功能、操作、状态、DS、B 类落地五维。控制台仅 1 条 favicon 404（环境噪音，与 v0 相同）。
3. **五维对照**：逐项对照 PRD §5 功能表与 product-review B 类要求。

## 二、功能覆盖（60/60 ✅，A2 勘误后口径）

### 2.1 交互级实测通过的代表项（含证据）

| 功能 | 断言证据 |
|------|----------|
| F011 撤销/重做 | heading(4) 后 doUndo 恢复原行=true；栈空提示 |
| F019-F023 查找替换五项 | openFind+findNext 选中命中=true；正则开关切换实测 |
| F022+B3 | Replace All：X9 全替换且 V1 清零=true、选区保持 selBefore=true、状态行"已替换 N 处"=true、doUndo 整体回退=true |
| F024+B2 | ⌘G/菜单 Find Next 语义驱动自研面板：选中值='V1'=true、状态行含"命中"=true |
| F030 大纲跳转 | 14 个大纲项；items[2].click() 后选区长度>0=true |
| F031+B7 | 成功态 "146 words \| 947 characters \| 1 min read"；清空后 "0 min read（B7 修复：旧版显示 1）"=true |
| F036/B1 标题 | heading(4) → 首行变 "#### PaperMD V1 演示文档"=true；Format 菜单含 Heading 1-6 全六级=true；工具栏 Heading 下拉可开（PAGE006 导航实测） |
| F040/F041 高亮 | overlay 引擎：tk-h1/tk-table/tk-table-sep/tk-task-done/tk-setext/tk-imgline/tk-html 七类 token 全命中=true |
| F042+B4 | tk-table（数据行）/tk-table-sep（分隔行）着色=true（旧版无表格高亮——已注明） |
| F043 续行 | "- 第一项"+Enter → "- 第一项\n- "=true |
| F044/F046 空项 | V1 呈现文档意图（删 marker/行合并）+ toast 注明旧版分支不可达（A2）；旧 App 真实行为=marker 残留已勘误至逆向/PRD 文档 |
| F045 缩进 | 非空项 Tab → "  - item"=true；⇧Tab 回退 → "- item"=true |
| F047 IME | 演示开关：输入期间 #hl innerHTML 冻结=true、imebar 显示=true、统计仍刷新（965 characters）=true |
| F048 光标保持 | 格式化/重渲染后选区恢复（各命令断言随行验证） |
| F014-F018 图片 | 插入 `![](welcome.assets/image-{13位ms}-{10位hash}.png)`=true；doUndo 文本回退=true（含撤销组 toast）；未保存文档裸名插入=true；commitSave('迁移演示.md') 后路径改写为 `迁移演示.assets/…`=true（F017） |
| F005/F006 关闭询问 | edited 态 closeWin → mCloseAsk 三选模态=true |
| F001/F005 保活 | 关窗后 reopen chip + Dock 重开按钮（PAGE001 场景）呈现 |
| F008/F051 自动保存 | 只读模拟：3 秒后"自动保存失败"toast=true（B5-②；旧版静默） |
| F009 导出 | buildExportHTML 含 h4/h6、thead/tbody、checkbox、pre>code、img、主题 CSS（max-width:800px）全=true |
| F010 导出 PDF | 打印面板 1.9s 后 btnDoPrint enabled=true（渲染完成时序显式化） |
| F028/F029 | sidebar collapsed 切换=true；专注模式三隐藏=true、退出还原=true |
| F049/F050/F052 | 字号 20px 即时生效=true；Dark/Light 主题 --syntax-heading 值 7db4ff/0366d6 切换=true |
| F053 欢迎文本 | newDoc 预填（评审动作实测） |
| F057/F058 | 工具栏 7 按钮呈现；无选区 .needsel 禁用态联动 |

### 2.2 忠实旧版事实/说明级覆盖（非缺失）

- F004（Open Recent 动态+Clear Menu）、F012（剪贴板降级提示）、F015（拖拽以模拟按钮替代）、F024 旧版差异注明、F025（拼写系统行为+连续关闭注明）、F041（按行重渲染等价模拟）、F055（帮助【未知】+C2）、F056（窗口菜单系统行为）、F059（**不设预览入口**——忠实旧版空壳，C1 留档）、F060（→B1 已修复为有入口，"部分实现"事实保留在评审面板）。
- 60 项功能无一丢失；未新增任何商业功能（云/AI/账号/插件零出现）。

## 三、操作覆盖 ✅

菜单 7 组全部可点开执行或给出系统行为说明（Format 下拉 13 项含 H1-H6+B1 标注实测枚举）；工具栏 7 按钮+Heading 下拉绑定真实动作（含禁用态）；查找面板 4 按钮（含 Prev）真实生效；偏好 3 控件即时生效；6 个模态确认/取消双路有效；Esc 关闭顶层模态=true；窗口红绿灯（关闭询问/最小化/缩放）与 Dock 重开实测有效；评审面板 B1-B8 核验按钮、PAGE001-014 导航、五态场景、3 开关、3 快捷动作全部有效。

## 四、五态覆盖 ✅

| 状态 | 实测 |
|------|------|
| 成功态 | welcome.md 样例：14 大纲项、七类高亮 token、146 words 统计 |
| 空数据态 | 清空 → 0/0/0 min read + 大纲空态引导文案「暂无标题 · 以 # 开始…」=true（B7/B8） |
| 加载态 | large-document.md → loading 遮罩 on=true（1.4s 后载入） |
| 错误态 | broken-encoding.md → alert 呈现=true 且不进自动保存（B5-⑦）；导出失败 alert=true（B5-①）；正则非法红字=true（B5-④）；无命中提示=true（B6）；只读保存/自动保存失败=true（B5-②） |
| 权限态 | mPerm 模态呈现=true（沙盒模型+剪贴板/拖拽降级说明） |

## 五、DS 一致性 ✅

- 样式表 `var(--token)` 引用共 **38 个**不同 token，全部定义于 docs/07_design_system/TOKEN.md（--syntax-*×13 / --bg-*×3 / --fg-*×2 / --separator / --accent / --overlay / --sidebar-width / --statusbar-* / --anim-focus / --radius-* / --outline-* 等）；组件样式无裸色值/裸字号（裸值仅存在于 token 定义块）。
- 明暗双主题：body.theme-light/theme-dark 双态定义，--syntax-heading 实测 0366d6↔7db4ff。
- 图标全部内联 SVG（对应 assets.md §1-§4），零外链、零图片请求。
- 已知近似（评审面板明示）：编辑器标题字号阶梯/等宽字体为 App 真实行为，原型以色彩+合成粗体近似以保证 textarea/pre 像素对齐。

## 六、B 类落地核验（P4 → V1）

| 编号 | 要求 | 核验结论 |
|------|------|----------|
| B1 | H4-H6 入口 | ✅ Format 菜单 ⇧⌘1-6 全六级（实测枚举）+ 工具栏 Heading 下拉 + heading(4) 生效 + 撤销 |
| B2 | ⌘G/⇧⌘G/⌥⌘F 联动 | ✅ 面板函数直驱（选中命中+状态行）；菜单三项绑定同路径；旧版差异注明 |
| B3 | Replace All 可撤销+视口保持 | ✅ 四断言全过（替换/选区保持/状态/撤销），按钮 tooltip 注明旧版不可撤销 |
| B4 | 表格高亮 | ✅ tk-table/tk-table-sep 实测命中；table-test.md 演示文档 |
| B5 | 七处静默失败反馈 | ✅ 全部可触发并实测四路（导出失败/自动保存失败/正则非法/破损文件），其余三路入口呈现（图片失败 toast、无命中、最近文档失效） |
| B6 | 计数/Esc/回绕提示 | ✅ "1/7 命中 · 已回绕到文档头"；Esc 关模态=true |
| B7 | 0 词阅读时间 | ✅ "0 min read" + 注明旧版怪癖 |
| B8 | 大纲空态引导 | ✅ 文案呈现 |

C 类（C1-C7）与 D 类在评审面板完整留档呈现，未擅自落地——符合"默认不做留档"。

## 七、缺陷记录与修复项

| # | 级别 | 描述 | 处置 |
|---|------|------|------|
| D1 | 非阻断 | 浏览器环境 favicon 404 控制台噪音 | 无需修复（file:// 打开不出现；与 v0 相同） |
| D2 | 非阻断（测试环境） | 并行会话争夺共享浏览器标签页，致两次断言运行到他人页面（null 引用）；重开专属标签后全过 | 环境问题，非原型缺陷（与 v0 验收 D2 同源） |
| D3 | 非阻断（断言脚本） | 两项断言初判 false：图片插入 regex 未考虑 assets 前缀、imgUndo regex 误匹配样例自带图片行 | 断言脚本缺陷；精确断言复测均=true，原型无缺陷 |
| D4 | **已修复** | 实测发现空列表项 Tab/Enter 与旧 App 行为差异 → 追溯源码与单元测试确认：旧 App 空项智能键分支不可达（`"- "` 不被 marker 识别，测试仅断言"不续行"） | 原型补注 toast 说明差异；同步执行 A2 勘误（reverse-analysis ⑤F044/F046+⑨-15、prd.md F044/F046）；node --check 复检通过 |

**阻断缺陷：0。未修复缺陷：0。**（D4 为验收过程中的文档勘误处置，非原型功能缺陷）

## 八、与基准文档一致性

| 基准 | 结论 |
|------|------|
| PRD | 60 功能 ID 全可追溯（交互级 47+/说明级 13，口径同 v0；F044/F046 已按 A2 勘误口径呈现"文档意图+差异注明"） |
| page-spec | 全局约定（菜单 40+ 项含快捷键/键位/禁用规则/主题色板）落地；11 维度逐页规格对应 14 视图 |
| product-review | B1-B8 全落地；A1/A2 勘误执行完毕；C1-C7/D1-D7 留档未擅动 |
| Design System | 38 token 1:1 映射 tokens.md；组件记录（components.md）与视图对应；patterns §4.1 快捷键全集入菜单 |

## 九、最终结论

# ✅ PASS

V1 新版原型达成全部验收标准：**60/60 功能零丢失、操作全覆盖、五态齐全（含权限态）、DS token 全映射、B1-B8 优化全部落地且差异注明、旧版 bug 行为零复制（修复后规格+注明）、单文件零外链、node --check 通过、67 项浏览器断言通过、0 阻断缺陷**。C 类 7 项决策点完整留档待用户确认（togglePreview/帮助/回溯上限/⌥⌘C 改键/TextKit2/隐患重写策略/storyboard 移除）。

移交备注：P7 架构五文件已就绪（模块拆分含公共能力归位映射与迁移清单），重写可直接按 module-split §4 清单执行。
