# Capability 追踪

> 状态：`Draft — Issue #2 tracer scope`
> 最后更新：2026-09-13

当前表只封闭 [TRACER-01](flows.md#tracer-01启动登录选址查看周边设施并退出) 的 required
Capability。每行从产品事实连到唯一 Owner、系统 Interface、状态/数据和验收证据；所有标识都在
所链接的系统文件中定义。[完整 Feature map](feature-map.md#capability-唯一归属)已为其余 37 项指定
唯一责任 Owner，但它们的 Interface、状态/数据与验收证据仍待系统设计步骤 2 补齐，不能视为完整追踪。

| Capability | 唯一 Owner | 系统 Interface | 状态/数据 | 验收场景 | 产品事实 |
| --- | --- | --- | --- | --- | --- |
| `NAV-01` | Application Shell | `AUTH-001`、`PRIVACY-001` | `STATE-SESSION`、`STATE-ACCOUNT-SCOPE`、`STATE-NAVIGATION` | `AT-START-01`、`AT-START-02`、`AT-START-03`、`AT-AUTH-02` | [Capability Catalog](../../knowledge_base/locatemy_product/capability_catalog.md)、[全局导航](../../knowledge_base/locatemy_product/features/global_navigation.md) |
| `NAV-02` | Application Shell | `SHELL-001` | `STATE-NAVIGATION`、`STATE-LOCATION` | `AT-LOC-01`、`AT-OUT-01` | [Capability Catalog](../../knowledge_base/locatemy_product/capability_catalog.md)、[全局导航](../../knowledge_base/locatemy_product/features/global_navigation.md) |
| `AUTH-01` | Authentication & Session | `AUTH-001` | `STATE-SESSION`、`STATE-AUTH-FORM` | `AT-AUTH-01`、`AT-AUTH-02` | [Capability Catalog](../../knowledge_base/locatemy_product/capability_catalog.md)、[登录与注册](../../knowledge_base/locatemy_product/features/authentication.md) |
| `MAP-01` | Map / Location | `LOCATION-001` | `STATE-LOCATION` | `AT-LOC-01`、`AT-LOC-02` | [Capability Catalog](../../knowledge_base/locatemy_product/capability_catalog.md)、[地图、选址与收藏](../../knowledge_base/locatemy_product/features/map_location.md)、[提交承诺](../../knowledge_base/locatemy_product/submission_commitments.md) |
| `MAP-03` | Map / Location | `LOCATION-001` | `STATE-LOCATION` | `AT-LOC-01` | [Capability Catalog](../../knowledge_base/locatemy_product/capability_catalog.md)、[地图、选址与收藏](../../knowledge_base/locatemy_product/features/map_location.md) |
| `MAP-06` | Map / Location | `LOCATION-001`、`SHELL-001` | `STATE-LOCATION`、`STATE-NAVIGATION` | `AT-LOC-01`、`AT-LOC-02` | [Capability Catalog](../../knowledge_base/locatemy_product/capability_catalog.md)、[地图、选址与收藏](../../knowledge_base/locatemy_product/features/map_location.md) |
| `FAC-01` | Nearby Facilities | `FACILITY-001`、`FACILITY-002` | `DATA-FACILITY-RESULT`、`CACHE-FACILITY` | `AT-FAC-01`、`AT-FAC-02`、`AT-FAC-03`、`AT-FAC-04` | [Capability Catalog](../../knowledge_base/locatemy_product/capability_catalog.md)、[周边设施](../../knowledge_base/locatemy_product/features/nearby_facilities.md)、[覆盖模型](../../knowledge_base/locatemy_product/nearby_facilities_scoring.md) |
| `ACCOUNT-07` | Authentication & Session | `AUTH-001`、`PRIVACY-001` | `STATE-SESSION`、`STATE-ACCOUNT-SCOPE`、`STATE-NAVIGATION`、`STATE-LOCATION` 及[私有清理清单](data-ownership.md#账户私有数据与队列清理清单) | `AT-OUT-01`、`AT-OUT-02`、`AT-SWITCH-01` | [Capability Catalog](../../knowledge_base/locatemy_product/capability_catalog.md)、[账户中心](../../knowledge_base/locatemy_product/features/account.md)、[登录与注册](../../knowledge_base/locatemy_product/features/authentication.md) |

## 完整性核对

- Tracer 的 8 个 Capability 均为 Issue #1 批准的 `required`，每项只有一个系统 Owner。
- 表内 6 个 Interface ID 均在 [Interface 注册表](interfaces.md#tracer-interfaces)定义；没有引用未登记 Interface。
- 表内状态/数据 ID 均在[状态与数据所有权](data-ownership.md#tracer-状态与数据)定义；退出涉及的
  非 tracer 私有数据只引用一个清理清单，不在此复制所有权。
- 表内 14 个验收 ID 均在[Tracer 验收场景](flows.md#tracer-验收场景)定义，并覆盖成功、完整空结果、
  可重试/不可重试失败、认证权限、账户切换和离线行为。
- 当前完成条件只适用于 Issue #2；Feature map 中的唯一 Owner 不是完整追踪链。系统步骤 2 和
  Baseline Gate 必须等全部 45 个 required Capability 都满足同一条链后才能完成。
