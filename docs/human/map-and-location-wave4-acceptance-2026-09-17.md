# Wave 4 Map / Location 验收报告

日期：2026-09-17。模块 Owner A。固定审查基点 `66f4ffc1e9392a1cdf9e01b054cbd81b713e82b9`，交付为该基点上的工作区改动；原有 Home 工作保留。当前模块证据见 [evidence](evidence/map-location-wave4-2026-09-17/)。生产代码、测试与 APK 的 SHA256 分别记录在 `test-source.json`、`device-build.source.json`、`production-build.source.json`；最终两台设备 build / verification / tests / production 六份 source hash 一致（`final-source-verification.txt`），旧真机证据不计入最终判定。

## 模块实现

**Implemented**。代码门槛与 GPT-5.6 Luna High 双轴复审通过；最终同源码模拟器与 Owner A 真机验收通过，无当前实现阻塞。

| 验收责任 | 实现与证据 |
| --- | --- |
| LOCATION-001：选点与角色 | 单点、A、B、property 独立；有限 WGS84 坐标；真实 DOSM/OpenDOSM 边界 RPC 最终校验；同点拒绝、不可变快照、晚到结果丢弃。`location_coordinator_test.dart`，`map_location_live_test.dart`。 |
| LOCATION-003：搜索 | Geoapify 马来西亚限定候选、防抖、过期丢弃、空与暂不可用反馈；候选仍经 LOCATION-001 校验。真实搜索非空及候选合法性通过。`location_adapter_test.dart`、live。 |
| 收藏与同步 | SQLite 按账户持久化 cache/create queue；重试次数及错误类别；远端权威、幂等 client key、版本冲突、软删除墓碑、离线禁止删除。真实双客户端与落盘关闭/重开/重放通过。`storage_adapter_test.dart`、`remote_adapter_test.dart`、live。 |
| 权限与关闭 | owner create/read/soft-delete allow；其他账户读取隔离、insert deny、update 无效；匿名 RPC/insert deny；物理删除 deny。真实 Privacy/Shell/MapRuntime 验证关闭、清理失败屏障、retry、A→B 与晚到响应。`map_privacy_test.dart`、`map_shell_test.dart`、live。 |
| LOCATION-002 | 声明式 visible/hidden 图层、视口版本拒绝、点击原 provider intent、长按 CreateHazardIntent，不改变地点角色；页面必须注入 MapLayerHost，可用独立 fake。`map_layer_test.dart`、`map_page_test.dart`。 |
| 错误与诊断 | RPC/HTTP/timeout/无效审计 metadata 类型化拒绝及恢复；固定事件、result、duration bucket、清洗关联 ID；诊断无私有输入，recorder 失败不阻断行为。`location_adapter_test.dart`、`map_diagnostics_test.dart`。 |
| 页面与本地化 | 中英 generated AppLocalizations；坐标/收藏名称无效字段焦点；私有弹窗跟随账户 Navigator 销毁；地图读屏摘要及本地化 marker 坐标说明；360dp / 200% 字体测试。`map_page_test.dart`。 |

边界真实样本包含 Shah Alam、Penang、Kangar、Langkawi、Kota Kinabalu，以及审计多边形精确顶点；海域与 Singapore 拒绝。边界 SDK 异常不会被误报成范围外：冻结接口未提供 transport-error variant，Map 返回现有 `scopeUnavailable` 并保留先前角色，不增改跨 Owner enum。

## 本期集成

Wave 4 到期项为 Map 与真实 Shell、Privacy、Supabase、SQLite、边界 RPC、Geoapify、OSM 接线。对应真实环境 live、真实 Shell/Privacy 协调测试及同源码最终双目标设备流程均已通过。

本次迁移只涉及 Map 收藏：增加 client key、版本、墓碑、read RPC；收藏外键由可选 `profiles` 改为必有的 `auth.users`，修复合法 Auth 账户无 profile 时排队无法重放的实机缺陷。远端迁移已应用，本地 Map 迁移版本与远端一致。已有 Home 迁移历史差异未在本任务中修改。

## 验证命令与环境

- `dart format --output=none --set-exit-if-changed lib test tool`：103 文件，零格式变化。
- `flutter analyze`：Map 范围无问题；全仓另有 21 项来自并行 Privacy 可读性整理的 `prefer_initializing_formals` info，不属于 Map 变更。
- `flutter test`：184 passed，6 个 opt-in live skipped；Map live 另行真实运行并通过。
- `python tool/verify_map_live.py`：关联开发 Supabase、真实测试账户与一次性第二账户；通过并清理测试记录/账户。
- `python tool/verify_map_devices.py --devices emulator-5554`，再以 `--devices <Owner A adb serial>` 单独运行：真实设备与模拟器、真实网络 Adapter，生产页面；isolated harness 存储与一次性账户。同源码两台设备均通过完整流程：READY、SELECTED、REJECTED、QUEUED、RESTART_QUEUED、RECOVERED、CLOSED；中英常规及 200% 字体截图、坐标输入/比较入口/分析路由通过。日志为 `final-emulator-verification.txt`、`final-physical-verification.txt`，各设备 APK 与 source hash 分别归档。
- debug APK 构建通过；APK 扫描排除高权限密钥及本地登录凭据；设备验收后恢复生产 APK、字体与超时设置，删除 harness 数据。

TDD 用户已确认 LOCATION-001/002、页面及外部 Adapter seams。红阶段证据 `review-regression-red.txt`、`adapter-regression-red.txt`、`queue-metadata-red.txt`、`diagnostics-red.txt`、`map-final-race-red.txt`、`map-font-red.txt`、`map-name-red.txt`、`map-selection-red.txt`、`map-dialog-red.txt`；最终测试证据 `tests.txt`、`live-test.txt`。

## Dart 可读性

按 Development Standard §7 明确手写构造参数、初始化关系及可命名局部类型，业务分派与集合处理使用普通条件/循环，地图与详情卡片拆为具名方法。Flutter 声明式 Widget 树及简单 SDK 回调保留惯用写法；sealed 结果和枚举的穷尽分支保留编译器检查，并在代码旁说明。构造形式的 analyzer 例外仅针对 `prefer_initializing_formals`，附文件级原因。

## Penpot 对齐

直接读取 Penpot MCP 的 `LocateMY · Mobile UI`，Map board `f8bc3597-5a95-809e-8008-a3e64de6acb5`。页面采用 SourceSansPro、`#155EEF` 主色、`#172033` 正文、`#667085` 次级文字、`#D9E0EA` 边线；圆角搜索框、单点/比较胶囊、右侧白色工具、底部 24px 圆角卡片、浅蓝适配度块、并排分析/收藏按钮。实机截图与原型视觉对照；Shell 保留共用标题/账户/语言及底部导航。原型的示例分数和分析数据不作为生产结果，提供方未接入时有明确文字。

## 后续集成

| 项目 | 主责/参与 | 最迟 Wave |
| --- | --- | --- |
| Cost、Crime 单点摘要/完整分析与比较 | B；Map/Shell A | 5 |
| Facilities、Transit provider 图层/分析 | A；Map/Shell A | 5 |
| Hazard provider 图层与创建页 | A；Map/Shell A | 5 |
| Infrastructure 分析/比较、Property 消费 property 地点 | B；Map A | 6 |
| Socio 分析与比较（不进入 Map 摘要） | B；Map A | 6 |
| Personalized Suitability 替换不可用槽位 | B；Map A | 7 |

当前分析/比较/图层任务页为明确后续接入槽位，保留原不可变地点引用；未实现未来提供方业务。`Integrated` 由项目负责人跨 Owner 验收后批准。本报告只判 Map 模块及其本期到期项，不宣告所有 Wave 4 模块完成。

## 当前阻塞

无。曾遇真机无线 ADB 离线；重连后最终全流程通过，补齐同源码证据。模块登记为 `Implemented`；`Integrated` 仍按项目负责人跨 Owner 验收批准。
