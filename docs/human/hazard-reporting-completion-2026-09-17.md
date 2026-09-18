# Hazard Reporting 完成与复验（Issue #25）

日期：2026-09-17。审查基准：`1e5acab14b665a896cc86c5e21dc0c657c9cc8aa`。
Issue #25 定义实现与集成门槛；功能规格以 `docs/design/features/hazard-reporting.md` 为准。

## 修复

“我的隐患报告 → 新建隐患报告”原来只发送返回地图意图，地图没有提示与继续入口。
现在地图提供上报入口、合法地点确认和取消，列表的新建按钮直接开启同一流程。
确认使用 Map 产生的 immutable reference，保留返回语境；无合法地点不可进入表单。
五类报告、作者管理、投票、公共图层及附近计数沿用现有真实实现。

## 验证

- 回归测试先失败：新建后找不到选点提示；修复后通过。
- `flutter test`：282 通过，11 项按配置跳过。
- `flutter analyze`：无问题。
- `python3 tool/verify_hazard_live.py`：3 项通过；真实两账户 / 匿名权限、五类发布、投票与撤回、本人状态 / 删除、不可变内容、2km pending-only 计数与 Shell / Map / Privacy 联合流程。
- 生产 APK：debug 构建成功；扫描未发现高权限 key 或本地登录凭据。
- 新增入口的中英文、360dp、100% / 200% 字体、重复确认与账户切换：4 项通过。
- `python3 tool/verify_hazard_devices.py --devices ...`：Android 模拟器与真实 SM_A528B 全流程通过，从真实列表新建入口选点发布，验证详情、投票、作者状态、取消及实际删除、中英文、200% 字体、离线保留输入、重启恢复、地图定位与关闭范围。
- 生产 APK、QA APK 及两设备证据均与最终源码 fingerprint 一致；测试结束已恢复设备设置、移除 QA APK、清理临时报告与账户。
- GPT-5.6 Luna High（`gpt-5.6-luna`，`high`）Standards / Spec 双轴最终审查完成，均为 0 项问题。

证据目录：`docs/human/evidence/hazard-reporting-completion-2026-09-17/`。
真实验证使用本地配置注入；临时报告、账户与独立 QA APK 在结束时清理。

## 完成判定

1. 本模块实现：`Implemented`；全部当前功能与新增入口、质量检查、真实后端、双设备验收和最终审查通过。
2. 本期集成：真实 Shell / Map / Privacy 联合与双目标设备复验通过。
3. 后续集成：Property Inspection 的风险快照消费者属于 Wave 6；Hazard count 提供端已真实验证。
4. 当前阻塞：0。`Integrated` 仍由项目负责人批准；本次不宣告整个 Wave 5 或 Issue #25 的其他模块已完成。

## Standards

GPT-5.6 Luna High：0 项文档规范违规、0 项需处理的代码异味。
建议批准本次修改：实现遵循既定架构及第 7 节可读性规则，验证与证据完整。

## Spec

GPT-5.6 Luna High：0 项问题。
真实新建入口与既有报告、图层、详情、投票、作者管理、恢复、权限和计数符合契约。
两目标设备、6 份 build / device 源码 fingerprint 和清理结果已复核，建议判定
Hazard `Implemented`、本期 Wave 5 集成证据完成。Property 消费者继续按 Wave 6 验收。

双轴发现总数：Standards 0，Spec 0；两轴均无未关闭问题。
