# Capability 追踪

> 状态：`Draft — Issue #2 tracer scope`
> 最后更新：2026-09-13

当前表只保留 Issue #2 tracer 的 8 条逐 Capability 追踪行。Issue #4 已补齐完整
[Interface 注册表](interfaces.md)、[状态/数据所有权](data-ownership.md)和[关键流程验收 ID](flows.md)，
但其余 37 项尚未逐行连接为完整追踪链；系统步骤 2 因此仍为 `In Progress`，不能把专题产物完整误判为
Capability 全量追踪已完成。

| Capability | 唯一 Owner | 系统 Interface | 状态/数据 | 验收场景 | 产品事实 |
| --- | --- | --- | --- | --- | --- |
| `NAV-01` | Application Shell | `AUTH-001`、`PRIVACY-001` | `STATE-SESSION`、`STATE-ACCOUNT-SCOPE`、`STATE-NAVIGATION` | `AT-AUTH-01`、`AT-SWITCH-01`、`AT-OUT-02` | [Capability Catalog](../../knowledge_base/locatemy_product/capability_catalog.md)、[全局导航](../../knowledge_base/locatemy_product/features/global_navigation.md) |
| `NAV-02` | Application Shell | `SHELL-001` | `STATE-NAVIGATION`、`STATE-LOCATION` | `AT-LOC-01`、`AT-OUT-01` | [Capability Catalog](../../knowledge_base/locatemy_product/capability_catalog.md)、[全局导航](../../knowledge_base/locatemy_product/features/global_navigation.md) |
| `AUTH-01` | Authentication & Session | `AUTH-001` | `STATE-SESSION`、`STATE-AUTH-FORM` | `AT-AUTH-01` | [Capability Catalog](../../knowledge_base/locatemy_product/capability_catalog.md)、[登录与注册](../../knowledge_base/locatemy_product/features/authentication.md) |
| `MAP-01` | Map / Location | `LOCATION-001` | `STATE-LOCATION` | `AT-LOC-01`、`AT-LOC-02` | [Capability Catalog](../../knowledge_base/locatemy_product/capability_catalog.md)、[地图、选址与收藏](../../knowledge_base/locatemy_product/features/map_location.md)、[提交承诺](../../knowledge_base/locatemy_product/submission_commitments.md) |
| `MAP-03` | Map / Location | `LOCATION-001` | `STATE-LOCATION` | `AT-LOC-01` | [Capability Catalog](../../knowledge_base/locatemy_product/capability_catalog.md)、[地图、选址与收藏](../../knowledge_base/locatemy_product/features/map_location.md) |
| `MAP-06` | Map / Location | `LOCATION-001`、`SHELL-001` | `STATE-LOCATION`、`STATE-NAVIGATION` | `AT-LOC-01`、`AT-LOC-02`、`AT-ANALYSIS-01` | [Capability Catalog](../../knowledge_base/locatemy_product/capability_catalog.md)、[地图、选址与收藏](../../knowledge_base/locatemy_product/features/map_location.md) |
| `FAC-01` | Nearby Facilities | `FACILITY-001`、`FACILITY-002` | `RESULT-*`、`facility_public_cache` | `AT-ANALYSIS-01`、`AT-COMPARE-03` | [Capability Catalog](../../knowledge_base/locatemy_product/capability_catalog.md)、[周边设施](../../knowledge_base/locatemy_product/features/nearby_facilities.md)、[覆盖模型](../../knowledge_base/locatemy_product/nearby_facilities_scoring.md) |
| `ACCOUNT-07` | Authentication & Session | `AUTH-001`、`PRIVACY-001` | `STATE-SESSION`、`STATE-ACCOUNT-SCOPE`、`STATE-NAVIGATION`、`STATE-LOCATION` 及[私有清理清单](data-ownership.md#账户私有数据与队列清理清单) | `AT-OUT-01`、`AT-OUT-02`、`AT-SWITCH-01` | [Capability Catalog](../../knowledge_base/locatemy_product/capability_catalog.md)、[账户中心](../../knowledge_base/locatemy_product/features/account.md)、[登录与注册](../../knowledge_base/locatemy_product/features/authentication.md) |

## 完整性核对

- Tracer 的 8 个 Capability 均为 Issue #1 批准的 `required`，每项只有一个系统 Owner。
- 表内 Interface ID 均在 [Interface 注册表](interfaces.md)定义；没有引用未登记 Interface。
- 表内状态/数据 ID 均在[状态与数据所有权](data-ownership.md)或 [Schema Catalog](../data/schema-catalog.md)定义。
- 表内验收 ID 均在[关键流程](flows.md)定义，并覆盖成功、完整空结果、分类失败、权限、账户切换和离线行为。
- 当前逐行核对只适用于 Issue #2；系统步骤 2 和 Baseline Gate 必须等全部 45 个 required
  Capability 都满足同一条链后才能完成。
