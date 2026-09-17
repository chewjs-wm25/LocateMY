# Nearby Facilities · Wave 5 实现验收

日期：2026-09-17。范围：Issue #25 开发规范下的 Nearby Facilities；不代表其他 Wave 5 Feature 的整体验收。事实源为 [Development Contract](../design/features/nearby-facilities.md)，[HTML 导出](nearby-facilities.html)仅作阅读交接。

1. **模块实现：Implemented**。生产路径已实现 FACILITY-001/002、真实 Overpass Adapter、公共 SQLite 24h 缓存、A/B、Shell marker/contribution、Map 图层与双语 Penpot 页面；全部实现检查与设备证据已通过，GPT-5.6 Luna High 最终代码与证据审查通过。
2. **本期集成：本模块截至 Wave 5 到期的联合子项已通过**。真实 Shell 导航/贡献及过期拒绝、真实 Map 换点/旧 viewport/完整图层、scope 生命周期均在公开 seam 验证。
3. **后续集成：Personalized Location Suitability**，Owner B 集成、Owner A 提供 FACILITY-001，最迟 Wave 7；必须复用五类设施事实，不自行查询 OSM、不把 unknown 当零。Integrated 由项目负责人跨 Owner 验收后批准。
4. **当前阻塞：无**。开发标准第 3、5 节所有当前适用门槛及用户要求的最终审查均已通过。

## 版本与环境

- 基础 HEAD：`29eec8d61a42fd85c809014b4fb8b3b66e2d9a69`；改动尚未提交。
- 代码指纹和检查结果：[checks.source.json](evidence/nearby-facilities-wave5-2026-09-17/checks.source.json)。指纹涵盖设施生产/测试代码、root/Shell 修改、设备 harness 和依赖清单；APK 与设备另附源代码指纹和 APK SHA-256。
- Flutter 3.47.2 / Dart 3.13.2；Owner A：SM-A528B Android API 34，无线 adb；Owner B：Android Studio AVD API 36，390×844。
- Device harness 使用真实认证、Privacy、Shell、Map、Overpass 和 SQLite。离线与 429 仅在外部 HTTP 边界注入；凭据从本地 loopback 临时获取，不编入 APK。QA 使用独立包名，保留其他任务应用与账户。

## 已完成检查

| 命令/操作 | 结果 | 证据 |
| --- | --- | --- |
| `dart format --output=none --set-exit-if-changed`（本次设施 Dart） | PASS | [format.txt](evidence/nearby-facilities-wave5-2026-09-17/format.txt) |
| `flutter analyze` | PASS，无问题 | [analyze.txt](evidence/nearby-facilities-wave5-2026-09-17/analyze.txt) |
| `flutter test` | 263 PASS，11 个需要显式开启的 live 测试跳过 | [full-tests.txt](evidence/nearby-facilities-wave5-2026-09-17/full-tests.txt) |
| `flutter test test/features/nearby_facilities` | 30 PASS | [tests.txt](evidence/nearby-facilities-wave5-2026-09-17/tests.txt) |
| `LOCATEMY_LIVE=1 flutter test test/live/nearby_facilities_live_test.dart` | PASS；真实五类数量 16 / 32 / 91 / 79 / 38；重建服务读到公共缓存 | [live.txt](evidence/nearby-facilities-wave5-2026-09-17/live.txt) |
| 独立 checkout 生产 `flutter build apk --debug` | PASS；敏感值扫描 PASS | [production-build.txt](evidence/nearby-facilities-wave5-2026-09-17/production-build.txt)、[源代码/APK 指纹](evidence/nearby-facilities-wave5-2026-09-17/production-build.source.json) |
| `python3 tool/verify_facility_devices.py --devices …` | 两台设备 ALL PASS | [Owner A verification](evidence/nearby-facilities-wave5-2026-09-17/owner-a-device-verification.txt)、[Owner B verification](evidence/nearby-facilities-wave5-2026-09-17/owner-b-emulator-verification.txt) |

## 规格覆盖与审查修复

按项目负责人确认的 FACILITY-001、FACILITY-002、页面公开交互做 red→green。测试覆盖：实际全量计数与最近三项分离、圆形边界、类别优先级、type/id 去重、Node/Way/Relation 代表点、完整空与 partial 区分、429/网络/超时/无效 payload、24h 精确过期/未来时间拒绝、SQLite 重开、缓存按当前地点绑定、刷新失败回落、较晚旧刷新不能覆盖新缓存、A/B 原顺序/同点/缺端、scope 关闭/换点丢弃、真实 Shell 贡献及过期拒绝、Map 旧图层隐藏/完整新层/旧 viewport 拒绝、来源版权、双语与 360dp/200% 字体。

GPT-5.6 Luna High 初审发现的问题已处理：缓存新增完整性、半径、映射版、归因、查询时间和 expiry；缺元数据的旧公共缓存安全失效；root 原样保留显式返回语境（null 注入当前 task）；贡献投影改为可见原结果卡。FACILITY-002 入口导出符合 owning contract，审查者已撤销该项；生产消费者没有直接读取原始 OSM 结果。换点等待期间隐藏旧设施层，防止旧地点结果误显。

§7 可读性检查覆盖本次手写 Dart：显式类型与初始化、完整方法/逻辑回调、普通控制流；Flutter 声明式 Widget 树、sealed typed outcomes 和框架生命周期保留；`prefer_initializing_formals` 局部说明用于遵循已确认 Java 阅读习惯。诊断仅固定 event/result、耗时区间和序列 correlation id，不打印账户、地点名称、坐标、payload 或凭据。

Penpot 对照：`10 · 周边设施`，board `f8bc3597-5a95-809e-8008-a3fa978b7889`，390×844；沿用 SourceSansPro、F6F8FB 页面、EAF2FF 摘要、白色分类卡、D9E0EA 边框、16/18 圆角、类别色与 16px 水平间距。使用真实数字；最近三项与大字体允许换行及纵向滚动，未使用原型示例数字冒充查询结果。

## 双设备完成证据

两台设备均完成：首屏、中英切换、200% 字体、离线缓存、refresh 失败回落、429 未缓存失败、同页 Retry 恢复、429 有缓存回落、真实 Map layer publish、A/B 原顺序、冷重启离线缓存、真实 sign-out 后旧 Shell contribution 拒绝。截图与 XML 为实际 UI 采集；verification 中的 LAYER_PASS / CLOSED_PASS 来自真实公共调用结果。每台设备的 verification.source.json 与 production/device build 的代码指纹一致。

- Owner A：[中文首屏](evidence/nearby-facilities-wave5-2026-09-17/owner-a-device-facilities-zh.png)、[来源和限制](evidence/nearby-facilities-wave5-2026-09-17/owner-a-device-facilities-zh-disclosure.png)、[失败](evidence/nearby-facilities-wave5-2026-09-17/owner-a-device-failure-zh.png)、[同页恢复](evidence/nearby-facilities-wave5-2026-09-17/owner-a-device-retry-recovered-zh.png)、[English 200%](evidence/nearby-facilities-wave5-2026-09-17/owner-a-device-facilities-en-200.png)、[A/B](evidence/nearby-facilities-wave5-2026-09-17/owner-a-device-compare-zh.png)、[重启缓存](evidence/nearby-facilities-wave5-2026-09-17/owner-a-device-restart-cached.png)、[版本](evidence/nearby-facilities-wave5-2026-09-17/owner-a-device-verification.source.json)。
- Owner B：[中文首屏](evidence/nearby-facilities-wave5-2026-09-17/owner-b-emulator-facilities-zh.png)、[来源和限制](evidence/nearby-facilities-wave5-2026-09-17/owner-b-emulator-facilities-zh-disclosure.png)、[失败](evidence/nearby-facilities-wave5-2026-09-17/owner-b-emulator-failure-zh.png)、[同页恢复](evidence/nearby-facilities-wave5-2026-09-17/owner-b-emulator-retry-recovered-zh.png)、[English 200%](evidence/nearby-facilities-wave5-2026-09-17/owner-b-emulator-facilities-en-200.png)、[English 200% 来源](evidence/nearby-facilities-wave5-2026-09-17/owner-b-emulator-facilities-en-200-disclosure.png)、[A/B](evidence/nearby-facilities-wave5-2026-09-17/owner-b-emulator-compare-zh.png)、[重启缓存](evidence/nearby-facilities-wave5-2026-09-17/owner-b-emulator-restart-cached.png)、[版本](evidence/nearby-facilities-wave5-2026-09-17/owner-b-emulator-verification.source.json)。

早期设备脚本的 adb 引号错误已修复；一次真实 Overpass 504 正确呈现 typed unavailable，重跑后两台设备完整通过。先前失败运行的日志属于历史诊断，不是最终结果；以上明确列出的截图、verification 和构建版本为最终验收依据。真实 Overpass live 测试之后只有其他模块修改 shared root；本 Feature 生产代码未变，最终 root 已重新通过全仓检查、APK 构建和双设备验证。OSM 为公开 HTTP 数据源，本模块无远程 RLS 或定位权限申请；有效地点与账户屏障通过当前真实 Map / Privacy / Shell 接入。

## GPT-5.6 Luna High 最终结论

审查模型：`gpt-5.6-luna`；reasoning effort：`high`。初审、修复复审及最终证据审查均由同一审查 agent 完成。最终结论：**验收证据审查通过，可判定 Implemented，当前阻塞无**。

审查确认五份版本 JSON 一致、27 个证据引用存在、所有检查与双设备流程齐全、代表性截图及 XML 符合 Penpot/双语/200% 可访问性要求。初审缓存元数据、返回语境、贡献投影问题已解除；FACILITY-002 暴露问题经 canonical contract 对照撤销。没有剩余真实实现阻塞；Suitability Owner B / Wave 7 是后续集成项。报告已依最终结论更新四段状态，保留负责人授予 Integrated 的边界。
