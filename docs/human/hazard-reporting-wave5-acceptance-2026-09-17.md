# Hazard Reporting — Wave 5 验收

2026-09-17；Owner A；GitHub Issue #25 开发与完成判定规范。设计依据为 `docs/design/features/hazard-reporting.md`，不是把 Issue #25 当作产品规格。审查基点：`29eec8d61a42fd85c809014b4fb8b3b66e2d9a69`。本工作树同时开发 Nearby Facilities / Public Transportation；本报告只判定 Hazard，不授予全 Wave 完成或 Integrated。

## 1. 模块实现

状态：**Implemented**。GPT‑5.6 Luna High 的 Standards / Spec 独立审查及末次恢复增补复审均通过；所有当前模块与 Wave 5 到期接线门槛通过。

真实能力：五类在线创建、trim / 字段校验、公开 viewport keyset 分页、partial 保留与后页重试、mine / 详情、作者 pending / resolved / 确认删除、单账户投票 / 改票 / 撤回、Privacy scope 门控与晚到请求丢弃、完整 2km pending 计数。生产入口使用 Supabase SDK / RPC，HTTP fake 只用于确定性测试和故障注入。无离线写队列。

| 验收 | 可观察证据 |
| --- | --- |
| AT-HAZARD-01 / 05 创建、失败保留 | service / Adapter / composer widget；live 非法境外引用拒绝、五类真实落库；设备未选类型、离线失败保留输入 |
| AT-HAZARD-02 地图 / 分页 / partial | 公开 HazardMapPanel 验证旧 viewport 丢弃、partial 有效行保留、后页失败及原 cursor 恢复、完整分页后刷新第一页、失效 cursor 重置；Adapter 有效子集返回 incompletePage；真实 MapLayerHost 与 Shell 详情路由 |
| AT-HAZARD-03 作者管理 | widget 删除取消与确认、状态双向切换；live A allow / B deny、不可变字段修改拒绝、删除后 notFound |
| AT-HAZARD-04 投票 / Privacy | real 双账户 up / down / none、本人票读、禁止他人枚举与匿名聚合；投票权威响应先更新，补刷失败保留新票；closing / A→B / late response 测试 |
| AT-PROP-03 提供方 | real 1999 / 2000 / 2001m 独立坐标算例、pending / resolved、UTC countedAt、radius 2000；partial 不转为成功 0；空 ID / 非法境外引用拒绝 |

质量证据位于 [evidence](evidence/hazard-reporting-wave5-2026-09-17/)。`quality.source.json` / `production-build.source.json` / 各设备 build 与 verification JSON 记录 Git 基点、工作树 source SHA256、Hazard scope SHA256 与 APK SHA256。共享 root 的其他 Feature 变动会改变 source hash；本地未提交修改以 hash 追溯。QA APK build 快照为 `8bdb19fa…`，设备 verification 为 `d5728303…`，末次恢复增补后质量 / production 为 `a19fc400…`：双设备完整验证期间仅本任务测试 formatter 与并行 Feature 的 root 改动，本模块生产代码未变；之后收尾补了 Refresh / expired cursor 的非视觉恢复分支，以公开 widget seam 的先失败后通过和最新 production APK 补验证，Luna 复审维持 Implemented；精确值与说明见 source-difference.txt，不把后续工作树 hash 冒充已装设备版本。

- `flutter analyze`：通过，analyze.txt。
- `flutter test test/features/hazard_reporting`：28 项通过，hazard-tests.txt。
- 已有 tracked 测试 + Hazard 测试：211 项通过，regression-tests.txt。
- `python tool/verify_hazard_live.py`：3 项通过，live-test.txt；环境为开发 Supabase `ntlhjfljkjeefzzqutbc`。第二账户无 profile，验证 Auth 唯一身份权威；临时报告 / 账户最终清理。
- `python tool/verify_hazard_build.py`：debug APK 通过、扫描无 service secret / 用户真实登录凭据，production-build.txt。构建在临时 snapshot，mobile `.env` 仅允许 public client 配置，不改共享 `.env`。
- `dart format --output=none --set-exit-if-changed .`：156 文件、0 changes，通过，format.txt。`flutter test`：263 passed / 11 opt-in skipped，通过，full-tests.txt。此前并行 Feature 未完成断言已由对应任务修正；早期失败保留在 full-tests-concurrent*.txt。

TDD 证据：先定义公开 scope / SDK / Widget 行为，观察失败，再实现；review-red.txt 包含五个审查缺陷的失败；page-retry-red.txt、partial-type-red.txt、count-location-red.txt、refresh-red.txt 对应后页 retry、专用 partial failure、真实境外 count 拒绝、完整分页后刷新的 red。当前通过结果覆盖这些失败场景。

Penpot MCP 核对 LocateMY Mobile UI 的 12 Composer、13 Mine、14 Detail boards：SourceSansPro、#F6F8FB 背景、#155EEF 主色、#172033 正文、#667085 次级字、白色圆角卡、胶囊类型选项、地点与蓝色公共提示区、宽主按钮。普通正文 / 按钮通过全局 textTheme 使用相同字体。生产页按契约不预选类型，不引入原型草稿功能。中英文全部页面 360dp / 200% 文本 widget 验证通过；设备图保留实际不同屏幕比例的布局。

可读性审查遵循 Development Standard §7；显式类型、完整方法体和显式初始化。必要例外是 Flutter super.key、collection-if 与跨 library marker implements interface；test fake 的未调用操作使用 noSuchMethod。MVVM 的交互状态在 ViewModel，外部 SDK 在 Data Adapter，root 负责真实依赖装配。

## 2. 本期集成

Wave 5 到期依赖已装配：Authentication / Privacy / Shell / Map + Hazard 真实 runtime；live 通过公开入口完成合法长按创建、远端读取、声明式图层、详情 / 返回 / Map、关闭账户后旧 seam 阻断。长按、marker 点击、定位仅改变地图相机或打开任务，不改 Location 单点 / A / B 分析角色。

最终设备验证通过：Owner A 无线真实 Android；Owner B Android Studio Pixel 6 Android 36 独立 emulator-5556。独立测试包 `com.locatemy.hazard.qa` + 独立 Privacy namespace，避免并行任务覆盖生产 APK。设备流程包括中英文、200% 投票撤回、删除取消、在线发布 / 投票 / 状态、离线保留、恢复、重启远端报告、返回列表 / 地图及 Privacy close。网络故障仅注入 HTTP Adapter 边界，正常流程仍连接真实 Supabase。

## 3. 后续集成

Property Inspection 原子风险 snapshot：Owner B 主责，Owner A 提供 Hazard / Safety 接口，最迟 Wave 6。Property 对同一合法坐标，仅 HAZARD-002 与 SAFETY-001 均完整 available 时整体保存；失败 / partial 保留旧组。当前已真实实现 Hazard 提供方，不以 Property 未到期消费阻塞本模块。Integrated 仍需项目负责人跨 Owner 批准。

## 4. 当前阻塞

**无。** 实现、真实环境、双目标设备、全仓质量与 GPT‑5.6 Luna High 双轴完成判定均已通过。

双设备原始完成日志见 [devices.txt](evidence/hazard-reporting-wave5-2026-09-17/devices.txt)。两台均 PASS，临时 QA 包、账户、报告、reverse 与字体设置最终清理 / 还原。中文首屏示例：[composer](evidence/hazard-reporting-wave5-2026-09-17/owner-a-device-composer-zh.png)、[mine](evidence/hazard-reporting-wave5-2026-09-17/owner-a-device-my-reports-zh.png)、[detail](evidence/hazard-reporting-wave5-2026-09-17/owner-a-device-detail-zh.png)；失败 / 重启 / 返回图与 XML 见同一目录各 stage。
