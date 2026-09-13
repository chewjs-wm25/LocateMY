# Module A：地图选址与灾害上报（Map, Location & Hazard Reporting）作业回顾

> 本模块由原"地图与位置""灾害上报"两块融合而成：灾害上报的入口与图层都在地图页，
> 与收藏位置共用同一张地图画布、同一套 Supabase/SQLite 数据通道与全局选址状态，
> 合起来构成 App 的"空间选址 + 地理信息收集"链路。
>
> 涉及文件：`lib/views/map/map_view.dart`、`lib/providers/location_provider.dart`、
> `lib/providers/hazard_provider.dart`、`lib/repositories/map_repository.dart`、
> `lib/repositories/geoapify_repository.dart`、`lib/models/saved_location.dart`、
> `lib/models/hazard_marker.dart`、`lib/core/cache/local_cache_service.dart`、
> `lib/views/account/reported_hazards_screen.dart`、`test/map_repository_test.dart`
>
> 对应数据实体：本地 SQLite `saved_locations`；云端 `user_saved_regions`（收藏）、
> `crowdsourced_hazards`（灾害上报）。

---

## Q1. Please briefly describe the module(s)/function(s) you engaged in the assignment. Indicate clearly the APIs and external libraries used.

本模块是应用的"选址工作台"，同时承担两类与地理位置相关的用户数据管理：

**地图交互与选址**方面，页面用 `flutter_map` 加载 OpenStreetMap 瓦片，支持点选落点、
拖动缩放、图钉标记与图层开关；通过 Geoapify Geocoding API（`autocomplete` / `search`
两个 HTTP GET 接口，带 `countrycode:my` 过滤与 API Key）配合 `flutter_typeahead`
做地点搜索联想；并区分"单点查看（display）"与"两地对比（comparison）"两种模式
（选中点 / 起点、终点）。所有落点先经 `isWithinMalaysia` 做马来西亚矩形边界校验，
落在范围外的操作会被拒绝。

**收藏位置（Saved Locations）的 CRUD 与双向同步**方面，用户可以把常用地点保存下来，
随时从列表跳回。新增时先生成以毫秒时间戳为 id 的 `SavedLocation` 写入内存列表，再
写入本地 SQLite 表 `saved_locations`（`ConflictAlgorithm.replace`），随后触发云端
同步；启动时从本地按创建时间倒序读回全部收藏；删除时先删本地，再按
`(user_id, district_id)` 精确匹配删除云端 `user_saved_regions` 的对应行（云端
`district_id` 存 `"纬度,经度"` 坐标串，并有 `user_id,district_id` 唯一约束）。
同步逻辑 `syncToSupabase` 查询本地 `synced = 0` 的行，逐条以
`upsert(onConflict: 'user_id,district_id')` 写入云端，成功后把本地行标记为
`synced = 1`——同一坐标重复保存不会产生重复行，失败重试也安全。

**灾害上报（Crowd-sourced Hazards）**方面，用户长按地图任意位置（或点上报按钮）
弹出底部面板，选择灾害类型（`HazardType`：flood / crime / traffic / infrastructure /
other，枚举自带图标与颜色）、填写标题与描述后提交。创建采用乐观更新：先用临时 id
把记录加入内存列表立即刷新界面，再调用 `saveHazard` 把
`{user_id, hazard_type, title, description, location, report_time}` 插入云端
`crowdsourced_hazards` 表（`location` 以 WKT `POINT(lng lat)` 写入 PostGIS 点列，
插入带 `.select()` 以确认服务端已处理）；成功后延迟刷新以取回服务端真实 uuid，
失败则回滚临时记录。读取分两种口径：`fetchHazards` 全量拉取用于地图图层展示，
`fetchUserHazards` 按 `user_id` 过滤、按 `report_time` 倒序拉取"我的上报"，供账户页
列表管理与删除（按主键 `id` 物理删除，成功后同步更新本地列表）。
解析函数 `parseHazardMarker` 兼容四种 `location` 返回形态——PostGIS 经 Supabase
REST 返回的 GeoJSON（坐标 `[lng, lat]`）、`SRID=4326;POINT(lng lat)` 文本、
普通 `{lat, lng}` 对象以及旧版顶层 `latitude/longitude` 字段。

此外，`LocationProvider` 作为全局共享的选址状态（选中点 / 起点 / 终点、当前模式），
被本模块以及生活开销、治安、社会经济、基础设施、交通等后续分析页共同消费，灾害
数据也同时服务治安页的"周边隐患"计数与房产检查的风险上下文。

使用的 API 与外部库：

- **Supabase / PostgREST**（`supabase_flutter: ^2.6.0`）：`user_saved_regions` 的
  `upsert(onConflict)` / `delete`、`crowdsourced_hazards` 的 `insert().select()` /
  `select()` / `delete().eq('id', ...)` / `.eq('user_id', ...).order('report_time', ...)`；
- **Supabase Auth**：`auth.currentUser.id` 作为两条业务表的用户归属外键；
- **SQLite**（`sqflite: ^2.3.3+2`、`path`）：本地 `saved_locations` 表与读写；
- **地图与坐标**：`flutter_map: ^8.3.2`（OSM 瓦片、Marker、MapController）、
  `latlong2: ^0.10.1`（`LatLng`、`LatLngBounds`、`Distance`）；
- **外部地理编码 API**：Geoapify Autocomplete / Search（经 `http` 调用）；
- **搜索联想 UI**：`flutter_typeahead: ^6.0.0`；**状态管理**：`provider`；
- 国际化经 `flutter_localizations` + 自生成 `AppLocalizations`（en/zh）；
- 测试基于 `flutter_test`，用真实抓包格式校验坐标解析。

---

## Q2. What are the strengths of the modules/functions created by you?

- **写入链路是"本地优先 + 云端幂等"**：收藏先落本地 SQLite 再异步同步云端，弱网下
  保存即时生效；同步用 `upsert(onConflict: 'user_id,district_id')` 命中真实唯一键，
  重复保存或失败重试都不会产生重复行，删除则按同一真实唯一键在云端精确命中，做到
  双端一致。
- **灾害上报采用乐观更新**：界面立即出现新标记，无需等待网络往返；失败能回滚临时
  记录，用户得到明确反馈而不是停留在加载态。
- **解析层对多种真实返回格式健壮**：PostGIS 几何经 REST 输出的形态随配置而变，解析
  函数集中收敛 GeoJSON / WKT / 裸字段多种格式，配有真实响应报文的单元测试，锁住
  "坐标不得写反、不得落到 (0,0)" 这类回归。
- **类型与状态单一来源**：`HazardType` 枚举同时驱动上报面板、地图标记与详情弹层的
  图标颜色；`LocationProvider` 统一维护单选与对比模式的选址状态，收藏、灾害和五个
  分析页都只读它，无需各自保存一份位置，并共享马来西亚范围校验。
- **单一数据表服务多个消费方**：`crowdsourced_hazards` 既是地图图层，又是治安页
  周边风险与房产档案风险上下文的输入，数据口径一致，不重复建表。
- **交互细节完整**：范围外长按被拒绝并提示、收藏弹层支持跳转定位与删除、上报
  面板按类型着色并支持多行描述，测试覆盖了主要解析分支。

---

## Q3. What are the weaknesses of the modules/functions created by you?

- **同步缺少完整的可靠性设计**：`syncToSupabase` 是"发出即忘"，没有重试队列、没有
  冲突合并，也没有"云端 → 本地"的下行同步——换设备或重装后收藏无法从云端拉回；
  且同步只在启动与每次新增收藏时触发，登录状态变化不会重新触发，未登录期间产生的
  记录可能长期留在本地不补同步。
- **本地写库路径缺少失败回滚**：新增收藏先把对象放进内存并通知界面，之后才写
  SQLite，写库异常时内存与磁盘不一致，没有兜底。
- **乐观更新依赖时序 hack**：灾害临时 id 与服务端 uuid 不一致，创建成功靠
  `Future.delayed(800ms)` 后整表刷新来"换回"真实 id，网络慢时会重复或错乱。
- **更新与投票未真正持久化**：`updateHazard`、顶/踩投票只改内存，没有对应的云端
  UPDATE，刷新即丢失；`crowdsourced_hazards` 的 `status`（pending/verified/
  resolved/rejected）也没有在读取与界面中体现。
- **数据读取较粗放**：地图一次性全量拉取全部上报、无分页无距离过滤，治安页的
  "周边灾害"实际是拉全量后在客户端算距离；错误处理大多只 `print`，UI 拿不到可操作
  的失败原因。
- **单页与范围控制偏简单**：`map_view.dart` 超过 1400 行，UI 与弹层、手势逻辑混在
  一起，维护成本高；马来西亚判定用矩形近似，海岸与岛屿边缘会有误判。

---

## Q4. What have you learned in doing this assignment?

- **"本地为主、异步上云"的移动数据层设计**：把用户地理数据设计成"本地先写 → 打
  `synced` 标记 → 逐条同步 → 成功后清标记"的状态机，比每次操作都等云端返回更稳、
  更快，也更适合弱网与断网场景。
- **唯一约束与 upsert 语义是关键**：PostgREST 的 `upsert` 默认按主键判断冲突，只有
  显式声明 `onConflict: 'user_id,district_id'` 才会按业务键合并；"冲突键决定写入
  语义"这一点直接决定同步是否幂等、删除是否能命中。
- **乐观更新必须同时设计回滚与最终一致**：先渲染后确认的手感好，但要提前想清楚失败
  回滚、以及如何用服务端真实主键替换临时主键——固定延时"等索引"不是可靠做法，
  `insert().select()` 拿回服务端行才是正解。
- **坐标与跨层序列化要集中处理**：GeoJSON 坐标是 `[经度, 纬度]`、WKT `POINT(lng lat)`
  也是经度在前，而 `LatLng` 是 `(纬度, 经度)`；这类差异应收敛到一个解析函数，并配
  真实报文单测锁住行为。
- **共享状态与数据归属**：把选址状态放进一个 Provider、用枚举驱动一套视觉语义，能
  明显降低多页面重复实现；同时理解到 `user_id` 外键、RLS 与"数据属于谁"的关系，
  客户端只需按归属过滤，权限控制留在数据库层更安全。

---

## Q5. What are the challenges, if any, you faced while working on this assignment?

- **云端"匹配键"选错过导致删除失效**：早期删除收藏用本地生成的 UUID 去匹配云端行，
  但云端 `alias` 存的是收藏名称、主键又是云端 uuid，删除永远落空；改成按
  `(user_id, district_id = "纬度,经度")` 这个真实唯一键后问题才解决，也让我明白本地
  id 与云端行并不总是同构。
- **重复同步触发唯一键冲突**：同步最初直接 insert，云端按 uuid 主键判断导致同一坐标
  再次同步必然命中 `(user_id, district_id)` 唯一约束报 duplicate key；显式声明
  `onConflict` 后才幂等。
- **经纬度顺序陷阱**：解析 GeoJSON 时曾把 `[lng, lat]` 直接当 `(lat, lng)` 用，标记
  一度落到坐标原点附近；用真实响应报文定位后统一在解析函数里交换顺序，并增加
  "必须落在马来西亚范围内、不得为 (0,0)" 的回归测试。
- **本地库的初始化与升级**：`locate_my_cache.db` 需要 `onCreate` 建两张表、`onUpgrade`
  平滑升版本（v1 → v2 新增 `saved_locations`），还要处理进程内单例避免重复开库。
- **地图页的体量与手势冲突**：长按上报、拖动、图钉点击、收藏弹层与模式切换在同一
  画布上互相干扰，功能堆叠使文件迅速膨胀；反复调手势判定与弹层焦点管理的过程让我
  体会到尽早拆分 widget 与分层的重要性。
