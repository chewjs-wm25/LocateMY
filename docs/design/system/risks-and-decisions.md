# 决定与实施风险（Issue #31）

[ADR 0017](../../adr/0017-minimal-account-and-online-user-records.md) 是精简决定。
保留地理资料原有 resolved／ambiguous／unresolved 与 provenance；不因为精简扩大坐标范围或选择默认地区。
保留部分 GTFS 来源的实际不可评分状态，不把受控算例称官方完整评分。

当前任务范围：精简既有实现、同步失效依赖与必要设计；完整预算／房产／若干分析后续按新契约开发。
旧认证／清理／通用导航测试不能继续作为开发门槛；仍有意义的公式、来源、归属和页面行为必须验证。
本次 schema migration 仅向前调整停用对象与风险可用性，不删历史 migration／远端用户数据。
旧表／字段兼容保留不代表相应 Flutter Feature 已实现，Schema proposed 状态继续清晰保留。

本次重构验收、未覆盖证据和 Luna 检查见 [执行检查](issue-31-validation.md)。
Integrated 仍由项目负责人批准；没有设备或真实环境证据时明确说明。

### `RISK-GEO-02` 资料决定与未关闭证据

- **项目负责人决定（2026-09-14）**：行政统计地理资料采用 DOSM OpenDOSM
  `administrative_2_district.geojson` 的 Git commit
  `21a78e98efd4cd9b022a27a1bf67d167076b7591`；实际导入审计还必须记录该文件的
  SHA-256 `3edb1022b2de371bba6b7afb9802b6fc6d747c86dbcc40abf2374a9134f3c561`。许可依据、
  固定文件链接与研究边界见[决策简报](../../research/geographic-context-boundary-source-decision-brief-2026-09-14.md)。
- **范围变更（2026-09-14）**：项目负责人确认警区多边形资料不可获取，故移除警区解析与 `SAFE-02`，
  `police_districts_boundary` 退役。Crime 仅消费行政边界解析出的州，并聚合 `crime_district.state`；不得以
  行政区、警局点位或第三方资料产生警区结果。
- **空间语义决定（2026-09-14）**：边界点或重叠区的每个覆盖行政区都是候选；多个候选一律完整返回
  `ambiguous`，不按面积、名称或邻近性挑选。此规则也约束统计州，因此州级治安在多州候选时不可用。源内
  退化环可在导入时修复为有效多边形；审计必须同时保留原始 source hash、修复标识和派生几何 hash。资料
  本身的重叠不裁剪、不合并。
- **本地资料验证（2026-09-14）**：已下载固定 commit，SHA-256 与批准值一致。PostGIS 3.5.2 验证 160 个
  `MultiPolygon`、16 个州/联邦直辖区、160 个唯一边界标识和 WGS84 SRID；7 个含退化环的几何经
  `ST_CollectionExtract(ST_MakeValid(...), 3)` 后均有效且非空，确定性派生几何清单 hash 为
  `929e7ce03417d284972f6550820806d0a29179f532b1c6c77f6bf5473bc1cb7f`。固定样本验证了非主离岛、
  边界点（两个候选）、零覆盖、合成重叠和不同资料版本；原资料有 311 对正面积重叠，其中 56 对跨州，均按
  `ambiguous` 保留。
- **远端关闭证据（2026-09-14）**：已关联 Supabase 项目已导入 160 行修复后边界及 1 行不可变审计；
  无效/空几何为 0，16 个州/联邦直辖区均在。稳定 RPC 对离岛返回 1 个候选、对固定真实边界点返回 2 个候选、
  对范围外点返回 0 个候选；每行均关联审计。authenticated 无直接表读权但可执行 RPC，anon 无 RPC 权限。
  外键覆盖索引与 GiST 空间索引均已建立。`RISK-GEO-02` 的资料、空间和读取风险已关闭；项目负责人已接受
  authenticated-only 受控 RPC 例外并于 2026-09-14 批准 Geographic Context 转为 `Ready for Development`。
