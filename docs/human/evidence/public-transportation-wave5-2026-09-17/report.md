# Public Transportation — Wave 5 验证报告（2026-09-17）

## 模块实现

状态：**Implemented**（指定模型双轴审查通过）。生产行为已完成，非整波 Wave 5 或 Integrated 批准。

- E1：`flutter test test/features/public_transportation --reporter expanded`：36 passed；严格来源/半径/日期/坐标映射、完整/partial/unavailable、served/no stops/no active routes、缓存/失败恢复、HTTP RPC 错误恢复、A/B 不可比原因/双方事实/显示交换/晚到、真实 Shell canonical slots/拒绝旧请求、真实局部 Map host/关闭、Marker/列表互选、35 Marker/30最近项、中文和 English 200% 字体及语义。见 [模块日志](module-test.log)。
- E1：`flutter analyze` 无问题；`dart format --output=none --set-exit-if-changed ...` 22文件0改动；全项目 `flutter test --reporter expanded` 278 passed / 11 opt-in skipped，公共交通 live 已另执行。见 [静态分析](analyze.log)、[格式](format.log)、[全量测试](full-test.log)。
- E2：`python3 tool/verify_transit_live.py`：真实 authenticated RPC、官方 snapshot、1.5km/服务日期/40站/10条路线/最近148m、16来源、正式grid version；未来日期明确 unavailable；匿名 RPC/表读取拒绝，authenticated 写入拒绝；1 passed。见 [真实测试](live-test.log)、[版本](live-test.source.json)。
- E3：真实官方 [下载审计](official-download-audit.json) 与 [导入审计](official-import-audit.json)：16个预期来源独立登记，15 usable + Kuantan failed；16976 stops、435 routes、37595 service dates、43034 stop-service links。Flutter 不下载/解析或自动同步 feed，真实 partial 不生成分数。
- E3：正式参照组9641点，`utm-wgs84-1km-stopcatchment-v1`；UTM固定原点1km中心，usable站点1.5km geography圆并集；服务范围外点/非正密度/负路线均0。见 [网格审计](reference-grid-audit.json)、[真实远端核验](remote-grid-integrity.json)、[重试实际核验](reference-grid-resume.log)。中断400行后续传和不同既有记录拒绝也通过，[可复现检查](reference-grid-recovery-check.py)、[日志](reference-grid-recovery-test.log)。准备前逐表核对 normalized snapshot；完整promotion核对整个审计网格。
- E3：本地 Docker Postgres 与真实开发 Supabase authenticated角色执行 `test/features/public_transportation/sql/transit_rpc_test.sql`，全部SQL断言通过并ROLLBACK：独立评分算例75、raw route facts、第30天/stale/日期范围、missing/failed/来源错配、no stops/no active routes、no batch16missing；新增 wrong-source missing 用例先RED再GREEN。见 [本地日志](sql-test.log)、[RED](sql-missing-source-red.log)、[远端命令及fixture hash](remote-sql-test.json)。受控真实SQL算例不是官方全资料结果，真实数据未改写且fixture泄漏0。
- E4：Owner A 真实 Android 与 Owner B emulator 均通过生产 `transitTaskViews` +真实 Auth/Privacy/Shell/Map/RPC 的 partial/date/A-B/双语/200%字体/返回/重启；[运行日志](device-run.log)、[APK与对应库源码hash](device-build.source.json)。设备XML保留 accessible names、范围/状态/分数语义及Marker距离类型文字；不靠颜色传递状态。
- E4：另用明示的 opt-in **受控外部Reader边界** served fixture 检查68评分卡及离线缓存，不将它当官方成功feed或真实评分算例。生产代码不包含该Reader；它仅在 `tool/public_transportation_device.dart`。见 [模拟器受控完整呈现](owner-b-emulator-controlled-served-settled.png)、[实机受控呈现](owner-a-device-controlled-served-settled.png)。
- E4：两台设备点击 Transit 返回按钮均走 typed `ReturnToMapIntent` 到真实 Map，原 Sunway Mentari 选择保留；[操作与版本](typed-return-map.json)、[实机Map](owner-a-device-typed-return-map.png)、[模拟器Map](owner-b-emulator-typed-return-map.png)。Shell tab 返回清理所有移除route slots，局部Map viewport同步失效并清理，晚到结果不可贡献到新请求。
- E4：按 Penpot MCP「11 · 公共交通」核对 #f6f8fb背景、#172033正文、#155eef主色、#0b1f44评分卡、SourceSansPro、16px边距、18/16px圆角及地图站点色。局部图按真实坐标呈现中心/1.5km圆，未把原型示意道路当实际道路。见 [实机真实partial](owner-a-device-partial-zh-settled.png)、[A/B](owner-a-device-comparison-zh-settled.png)、[实机200%](owner-a-device-large-font-en-settled.png)、[模拟器200%](owner-b-emulator-large-font-en-settled.png)。
- `python3 tool/verify_transit_build.py`：当前生产 debug APK 构建通过；临时源副本仅公开URL/key资产，真实测试凭据/service key扫描PASS。见 [日志](production-build.log)、[版本与扫描](production-build.source.json)。

当前生产APK与设备harness的库源码SHA256均为 `7f8ab788e9574bc2352b98e96b1586ab29e1ede0e04f1734e2c7b67d2dcbf7a3`。完整改动版本记录见 [源码清单](current-source.json)；工作区包含其他任务并行改动，不以base HEAD单独标识未提交代码。

## 本期集成

**通过。** 当前Wave5的Shell真实单点/A-B task、immutable return context、canonical contribution、返回地图、独立MapLayerHost和scope/过期隔离均已接入生产composition root，并由最高公开seam与上述设备验证覆盖。generic地点分析菜单可选公共交通明确日期或周边设施；后者既有路径保留。

## 后续集成

- Infrastructure Coverage：A提供同一canonical交通结果，B主责真实接入，最迟Wave6。
- Personalized Location Suitability：A提供同一canonical交通结果，B主责真实接入，最迟Wave7。

消费者不重读GTFS或重算交通分。尚未到期的消费者不阻塞本模块；Integrated仍由项目负责人跨Owner批准。

## 当前阻塞

无当前实现验收阻塞。来源Kuantan失败是已覆盖的合法partial状态，不是将业务数据伪装为完整的理由；需维护者后续手动准备新的可信snapshot，才能出现官方完整交通分。

## E5 — GPT-5.6 Luna High

Standards和Spec两轴多轮只读复核，真实缺陷均按用例修复；撤回parent/task身份误判和将Python dict当Dart Map的误判。最终判定记录见 [审查结论](luna-final-review.json)，复核只读取源码和build证据，不读取human文档。
