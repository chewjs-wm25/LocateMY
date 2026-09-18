# GPT‑5.6 Luna High：Home Wave 4 两轴审查

> 2026-09-17；模型 `gpt-5.6-luna`，reasoning `high`；独立 Standards / Spec 两个审查 agent，并行初审、逐项修复、复审。
> 基线：`66f4ffc1e9392a1cdf9e01b054cbd81b713e82b9`；范围包括工作区 diff 和未跟踪的新 Feature、测试、迁移及工具文件。

## Standards

最终代码审查 **PASS**，没有硬性规范阻塞。Domain 不依赖 Flutter、Supabase 或 SQLite；生产组合根消费唯一公开 Home 入口。

初审发现的诊断事件缺口（architecture Observability）已通过 HOME-001 的固定结构事件和敏感字段 deny-list 测试关闭。版本追踪缺口已通过 App source stamp 与独立 SQL/Python revision 清单关闭。最终设备证据是单独的外部验收门槛，现已补齐并复核通过。

保留三项可维护性判断，均不是发布阻塞：

- possible Duplicated Code：Application 与 SQLite Adapter 重复提取来源日期。
- possible Primitive Obsession：数据集 ID、状态与方向采用字符串。
- possible Adapter boundary smell：内部 HomeReader 使用动态 JSON map 作为评分输入。

## Spec

最终代码审查 **Implemented — PASS**；没有进一步的 Home 契约代码阻塞。关闭三项缺陷：

- 五年窗口不足时回退至全部较早的同频有效历史，仍保持月度 24 / 季度 8 的最低观测要求。月/季两项公开失败测试已转绿。
- GDP 字段或数据异常会分类为经济卡不可用，使综合结果 partial；不替换缓存、不启动成功冷却。有效空 GDP 输入保留其余 70% 权重归一化。schema/data 两项公开失败测试已转绿。
- 可用缓存卡片及综合来源拒绝占位观测日期；不可用卡片仍可携带未知日期。SQLite 损坏公开失败测试已转绿。

真实 Map 页面及完整地图联合验收仍是 Owner A 的 Wave 4 集成责任，不是 Home 生产评分的替代实现。

## 证据与最终门槛

[验收报告](home-and-relocation-outlook-wave4-acceptance-2026-09-17.md) 汇总模块实现、本期集成、后续集成和当前阻塞。最终代码测试：36 项 Home/Shell、145 项全量通过（5 项 opt-in 跳过）、真实 live 1 项通过；格式、静态分析和 diff 检查通过。源码及迁移/工具版本清单随证据保存。

规范轴：0 代码阻塞、3 可选判断；规格轴：0 代码阻塞，3 项缺陷已关闭。最终两设备与 APK 证据已通过并经 Luna Standards 复核；Home 模块达到 Implemented。
