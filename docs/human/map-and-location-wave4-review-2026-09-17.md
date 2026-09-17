# Wave 4 Map / Location — GPT-5.6 Luna High 审查

固定点：`66f4ffc1e9392a1cdf9e01b054cbd81b713e82b9`。审查范围为 Map / Location 新增及 composition root、l10n、收藏迁移、测试与验收证据；工作区原有 Home 改动排除。按 code-review skill 分别进行 Standards 与 Spec 两个只读审查，均使用 `gpt-5.6-luna`、`high` reasoning，并在修复后复审。

## Standards

| 初始发现 | 处理结果 |
| --- | --- |
| ViewModel import/cast 具体 LocationService，读写内部状态 | 新增 Application MapWorkspace seam，页面必须注入 MapLayerHost/MapWorkspace；ViewModel 只消费接口；搜索类型移至 Application。独立 fake host 页面测试通过。 |
| 边界 SDK 异常逃逸公开接口 | Adapter 20s timeout，HTTP/timeout/无效 metadata 映射为 typed unavailable；Service fail closed，用冻结接口现有 scopeUnavailable 拒绝，不捏造 outsideMalaysia。红→绿及恢复测试通过。 |
| 双语硬编码、marker 读屏名称不清楚 | Map、坐标弹窗及当前 future destination 全迁 generated ARB；marker 采用本地化角色/经纬度说明，地图独立语义容器汇总所选地点，保留子控件语义。 |
| 缺少诊断事件与敏感字段断言 | 注入可选 recorder，固定事件/result/耗时桶/进程关联 ID；成功、重试、不可重试、缓存降级、冲突、privacy failure 和 deny-list 测试通过，recorder 不影响业务结果。 |
| §7 可读性遗漏 | 显式构造/局部类型、完整方法体、条件/循环花括号、具名工具分派和候选选择、独立摘要循环与图层 ID 集合已修正；SDK Widget 树与 sealed 穷尽分支保留必要惯用写法。 |
| 设备/本地化证据待完成 | 同源码模拟器与真机最终重跑均已通过并归档，source hash 与测试/生产构建一致。 |

复审 P3 测试循环显式类型建议也已修正；不改测试行为。

LocationService 的内部类拆分建议属于设计判断；Development Standard 允许 Owner 自定内部类数量，公开依赖方向已修复，未为类数量改变冻结跨 Owner 接口。

## Spec

| 初始发现 | 处理结果 |
| --- | --- |
| LOCATION-002 页面无法注入 canonical fake | 页面必须注入 MapLayerHost；使用非具体 coordinator wrapper 和独立 host 的长按回归通过，单点角色不变。 |
| 关闭中的长按误返回 unauthenticated | 返回 scopeUnavailable；红→绿通过。 |
| await 后关闭中的贡献误返回 staleViewport | 账户与视口判断分开；晚到 contribution closing 回归红→绿通过。 |
| 审计版本空字符串仍被接受 | 非空 trimmed source_version 加合法双 SHA256；empty-version/recovery 回归通过。 |
| 晚到范围外结果覆盖当前页面反馈 | VM 选择版本守卫及 Service scope/request 优先级修复，真实异步回归红→绿。 |
| 收藏无效名称关闭弹窗，Unicode 长度不一致 | 独立名称弹窗保留无效反馈/焦点；长度按 Unicode runes，120/121 字符边界回归通过。 |
| 保存弹窗跨账户导航销毁仍保留 | TDD 复现旧 AlertDialog 留存；Map 弹窗跟随私有 Navigator，账户页面销毁后弹窗和私有名称不再可见。 |
| 可访问性与最终设备验收未关闭 | 小屏 200% 实机截图发现工具文字裁切，新增完整 TextPainter 高度断言并修复自适应工具宽高/滚动；最终模拟器与真机中英 200% 截图均已更新、核对通过。 |

后续真实分析页、比较结果与 provider 图层仍按验收分配在 Wave 5–7 接入，有明确 Owner/期限。占位页面不计算提供方结果；未来 joint work 不作为本期 Map 实现缺陷。

## 最终判定

最终冻结代码经 `gpt-5.6-luna` / `high` 双轴复审：Standards 通过，无适用规范违规；Spec 通过，无代码层阻塞。184 项测试通过、6 项 opt-in 跳过，Map analyze clean，103 文件格式检查零变化。

最终同源码真机与模拟器全流程及中英 200% 截图均已通过，六份 source hash 一致。最后设备证据缺口已关闭；Map 可判定 **Implemented**，无当前阻塞；未来 Wave 5–7 联合接入有 Owner/期限，未声明 `Integrated`。完成报告与证据见 [验收报告](map-and-location-wave4-acceptance-2026-09-17.md)。

补齐真机证据后，同一 GPT-5.6 Luna High 两位只读审查者再次明确确认：Standards / Spec 最终门槛均通过，Map / Location = `Implemented`，当前阻塞为零。最终审查摘要见 [luna-final-review.txt](evidence/map-location-wave4-2026-09-17/luna-final-review.txt)。
