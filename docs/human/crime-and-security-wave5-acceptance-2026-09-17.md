# Crime & Security · Wave 5 验收（2026-09-17）

规范：[Issue #25](https://github.com/chewjs-wm25/LocateMY/issues/25)、[开发标准](../design/development-standard.md)；规格：[owning contract](../design/features/crime-and-security.md)。测试边界由项目负责人确认：页面入口、唯一安全分析服务、真实只读 Adapter/RPC。审查模型为 GPT‑5.6 Luna，High。

## 交付行为

真实登录业务树中的单点与 A/B 治安页面接入地图选点、Geo 统计州、Supabase 只读 RPC 与 SQLite。提供 60:40 安全指数、类别与具体类型筛选、五年折线趋势、缺失/部分/失败及重试。筛选不重算评分，A/B 同口径且两侧完整时显示 B−A；交换同时交换地点和差值方向。

真实镜像与官方 CSV 全字段、业务键和内容一致：19,152 行，最新完整年 2023。排除全国、警区汇总和 type 汇总，避免重复计算。Selangor 为 13,739（暴力 2,953、财产 10,786），Johor 为 5,330；数据与代码内部保存来源校验，页面不显示技术元数据。按既定 inclusive percentile 公式 Selangor 分数为 0，不表示没有案件，也不构造未批准的评级阈值。

## 命令、环境与版本

Linux；Flutter 3.47.2 / Dart 3.13.2；真实 Supabase 开发项目；Owner A Samsung SM_A528B Android，Owner B sdk_gphone64_x86_64 Android 模拟器。普通应用 UI 与服务真实接线；仅自动登录与网络切断由隔离 QA 启动入口/loopback fixture 提供。凭据只在运行时注入，不放入 APK；测试不保存房产或用户地点记录。APK 使用允许列表公共配置，保留 SHA256 和敏感信息扫描结果。

生产代码版本 `7ed4d7f319a22c70766b6b04d87c66c7d4cd0ac1`；完整 lib Dart 的 SHA256 清单摘要为 `9f9aec838c464d62024ebe6fddaaf8343ddba6d2c914dcaa05c181a8efa250ae`。首次设备截图发现英文 200% 标题截断；新增失败断言后修正标题换行与大字体地图图标，重新运行全量检查、构建与设备验收。额外读屏文字断言通过 8 个页面测试，见 [page-accessibility.log](evidence/crime-security-wave5-2026-09-17/page-accessibility.log)；它只增强测试，不改变上述生产代码摘要。

| 验证 | 命令 / 操作 | 结果与证据 |
| --- | --- | --- |
| 格式 | `dart format --output=none --set-exit-if-changed` 本次 Dart 文件 | 21 文件，0 改动；[format.log](evidence/crime-security-wave5-2026-09-17/format.log) |
| 静态检查 | `flutter analyze` | No issues；[analyze.log](evidence/crime-security-wave5-2026-09-17/analyze.log) |
| 全仓测试（测试提交 `7c729df`） | `flutter test --reporter expanded` | 235 通过，10 个未启用的 live 测试跳过；[all-tests.log](evidence/crime-security-wave5-2026-09-17/all-tests.log) |
| 真实 RPC / Geo / 权限 | `python3 tool/verify_crime_live.py` | 1 个 opt-in live 测试通过；[live-test.log](evidence/crime-security-wave5-2026-09-17/live-test.log) / [source.json](evidence/crime-security-wave5-2026-09-17/live-test.source.json) |
| 官方数据与镜像完整审计 | `python3 tool/verify_crime_source.py` | 全内容一致；[official-source-audit.json](evidence/crime-security-wave5-2026-09-17/official-source-audit.json)；未导入/替换镜像 |
| 生产 debug APK | `python3 tool/verify_crime_build.py` | 构建成功，敏感信息扫描通过；[production-build.source.json](evidence/crime-security-wave5-2026-09-17/production-build.source.json) |
| 两设备真实流程 | `python3 tool/verify_crime_devices.py --devices <Owner B emulator> <Owner A Android>` | Owner A/B 全部通过；[A](evidence/crime-security-wave5-2026-09-17/owner-a-device-verification.json) / [B](evidence/crime-security-wave5-2026-09-17/owner-b-emulator-verification.json) |
| Luna High 双轴审查 | 基线 946c607… → 7c729df…，独立 Standards / Spec | 无生产阻断；[审查记录](crime-and-security-wave5-luna-review-2026-09-17.md) |

## TDD 与验收分配

先在最高公开边界写失败断言，再实现对应生产行为。公开 service 覆盖公式、类别缺失、零值和平分、territory 映射、来源不可验证、历史缺口、Geo 歧义、持久缓存/过期/损坏/并发晚到；真实 SDK HTTP 边界覆盖映射与 503 后恢复。页面测试覆盖筛选、A/B、地图参数、房产槽位、中文/英文 320dp 200% 字体与读屏语义。应用生命周期测试验证换号、退出、dispose 后晚到结果；真实登录设备流程验证退出后的业务树关闭。

CS01–CS03、CS05、CS09：本模块 service/widget/Adapter/live 证据；CS04 Geo、CS06 A/B、CS07 地图返回、CS08 Auth：本期真实上游接线与联合路径；CS10：Penpot、双语言、语义、小屏和设备证据。CS11 本模块公开风险读数与地点参数已验证，真实房产消费属于 Wave 6。

## UI 与可读性

读取 Penpot MCP board `f8bc3597-5a95-809e-8008-a3fa91b70d32`（07 · 治安与犯罪）。使用 Source Sans Pro、#F6F8FB 背景、#0B1F44/18dp Hero、#155EEF 胶囊筛选、白色/16dp 图表和 #EAF1FF 说明。真实数据替代原型示例 74/2025；按事实源使用折线，缺失年份断线并配逐年文字。页面没有来源 hash、抓取时间或重复技术提示。

手写 Dart 使用显式类型、构造初始化、完整回调及具名动作；Data Adapter 隔离 SDK/SQLite。保留 Flutter 声明式 Widget 集合/条件元素及简短 UI 条件表达式；不可变快照保留 final，必要的 dynamic 限于 JSON/SDK 输入映射。公开 seam 无逐层包装或新增跨模块框架。

## 完成判定

- 模块实现：**Implemented**；CS01–CS11 本模块责任通过，格式、分析、235 项测试、真实 live、两设备及 debug APK 证据齐全，Luna High 未发现生产阻断。
- 本期集成：CS04、CS06–CS08 到期真实 Geo / 地图 / Auth / RPC 联合路径全部通过；Owner A Android 与 Owner B 模拟器最终验证均 PASS。
- 后续集成：B 主责，Wave 6 接入真实房产新增/坐标修改安全风险消费及快照；当前入口明确标为未实现槽位。
- 当前阻塞：**无**。Integrated 仍由项目负责人批准；本模块完成不等于整个 Wave 5 的其他 Feature 已完成。

证据目录：[README](evidence/crime-security-wave5-2026-09-17/README.md)。[Owner B 模拟器单点截图](evidence/crime-security-wave5-2026-09-17/owner-b-emulator-single-zh.png)、[英文200%截图](evidence/crime-security-wave5-2026-09-17/owner-b-emulator-single-en-200.png)。

[Owner A 实机单点](evidence/crime-security-wave5-2026-09-17/owner-a-device-single-zh.png)、[实机英文200%](evidence/crime-security-wave5-2026-09-17/owner-a-device-single-en-200.png)、[证据 SHA256 清单](evidence/crime-security-wave5-2026-09-17/manifest.json)。远端前向 migration `20260917094631_crime_security_read_api` 已应用；没有重置或删除现有数据。
