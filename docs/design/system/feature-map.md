# Feature 与 shared module 边界

> 状态：`Draft — Issue #2 tracer scope`
> 最后更新：2026-09-13

本文件登记系统责任的唯一归属。当前只关闭[关键旅程 tracer](flows.md#tracer-01启动登录选址查看周边设施并退出)
经过的边界；未列出的 required Capability 仍待系统设计步骤 2–3 处理，不能从本文件推断其 Owner。

## Tracer Owner

| Owner | 类型 | 拥有的 Capability | 拥有责任 | 明确不负责 |
| --- | --- | --- | --- | --- |
| Application Shell | shared module | `NAV-01`、`NAV-02` | 认证门控、首页/地图一级导航、业务导航意图、跨 Feature 旅程编排；只在账户范围关闭后开放私有路由 | 认证凭据、地点状态、分析计算、任何 Feature 的私有记录或离线队列 |
| Authentication & Session | Feature | `AUTH-01`、`ACCOUNT-07` | 当前设备的会话恢复、邮箱密码登录、退出和真实会话结果 | 主应用导航、业务私有状态清理、其他设备会话 |
| Map / Location | Feature | `MAP-01`、`MAP-03`、`MAP-06` | 可变地点上下文、马来西亚范围校验、单点显示、合法分析目标和分析导航意图 | 分析结果、设施缓存、认证会话、应用级路由 |
| Nearby Facilities | Feature | `FAC-01` | 2 公里 OSM 设施查询、五类归类、圆形过滤、结果语义、24 小时公共缓存和归因 | 地点选择、0–100 评分、设施质量/路线、账户私有资料 |
| Account Privacy | shared module | 无直接 Capability；支撑 `NAV-01`、`ACCOUNT-07` | 账户范围开启/关闭协议：只为已认证账户开放隔离读取；关闭时阻断旧范围读取，要求每个私有状态 Owner 清除本机状态，并汇总完成或失败 | 各 Feature 数据语义、远端权威记录删除、公共缓存和语言偏好删除 |

Application Shell 与 Account Privacy 是深 shared module：前者把认证门控和跨 Feature 导航规则藏在
一个业务导航 Interface 后；后者把账户隔离与“退出已完成”的全量清理条件藏在一个账户范围
生命周期 Interface 后。
删除任一模块都会把同一规则散回多个 Feature，因此两者均有独立存在的必要。

## Tracer 责任链

| 旅程步骤 | 执行 Owner | 直接依赖 | 完成条件 |
| --- | --- | --- | --- |
| 启动并判定入口 | Application Shell | Authentication & Session、Account Privacy | 只有已恢复会话且对应账户范围已打开时进入主应用；其余状态保持门控 |
| 邮箱密码登录 | Authentication & Session | 外部 Supabase Auth；Application Shell 消费结果 | 返回已认证会话，或明确的可重试/不可重试结果；不以页面跳转代替成功 |
| 进入地图并选择地点 | Map / Location | Application Shell 接受导航意图 | 产生经马来西亚范围校验的不可变地点引用；范围外输入被拒绝 |
| 进入周边设施分析 | Map / Location 发意图，Application Shell 编排 | Nearby Facilities | 合法单点被作为显式输入传入；没有地点时不导航且不使用默认城市 |
| 读取一次分析结果 | Nearby Facilities | OSM Overpass、Feature 自有公共缓存 | 显示新鲜、缓存、完整空结果或不可用之一，且来源、范围、时间和原因完整 |
| 退出并清理 | Authentication & Session 结束会话；Account Privacy 关闭范围；Application Shell 完成门控 | 所有账户私有状态 Owner | 当前设备会话结束、旧账户本机私有状态全部清除后才显示登录页；公共缓存和语言偏好保留 |

## 依赖方向

- Feature 通过系统 [Interfaces](interfaces.md) 协作，不读取其他 Feature 的 ViewModel、Adapter、DTO
  或存储结构。
- Application Shell 只消费领域结果和业务导航意图；分析 Feature 只接收不可变地点引用，不读取
  Map / Location 的可变地点上下文。
- Account Privacy 协议验证清理是否完整；具体私有状态、缓存和离线队列仍由各 Feature 独占。
- Nearby Facilities 的外部来源与缓存 seam 属于其 Implementation，不扩散到调用者。

## 尚未登记

其余 required Capability 的 Feature/shared module 边界、完整依赖 DAG 和设计波次仍待系统设计后续
步骤。当前 tracer 没有授权为 A/B 比较、其他五类分析、收藏同步、隐患、预算或房产实勘规定
额外业务 Interface。
