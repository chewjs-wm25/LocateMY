# Schema Catalog

> 状态：`Baselined — 5d11769; environment control amended 2026-09-15`
> 最后更新：2026-09-13

本文件是 LocateMY 数据对象、字段契约、访问规则和迁移状态的唯一目录，不替代可执行 schema。Supabase DDL/RLS/Storage policy 最终以 `supabase/migrations/` 为权威；SQLite 以实现的 migration 为权威。系统与 Feature 文档只能引用这里的对象，不复制字段定义。

## 状态与类型

- `proposed`：系统/Feature 设计目标，尚无对齐的实现。
- `implemented`：现有 migration 已建立且语义与本目录一致；后续仍须以测试证明访问规则。
- `deprecated`：不得被新设计消费，须记录替代对象或无损迁移前置条件。
- 外部 `auth.users` 与第三方来源标为 `external`，不由本项目迁移。

字段类型使用语言无关类别；具体 Postgres/SQLite 类型由 migration 固定。所有时间为带时区时刻，除政府数据集的 `date` 统计日期。所有坐标使用 WGS84，经度/纬度或 Point 表达必须在 owning design 选定一种公开形状。

## 对象目录

### 身份与账户业务对象

| 对象 | 类型 | 状态 | Owner | 关键字段与约束 | 访问规则 / 消费者 | 实现或迁移方向 |
| --- | --- | --- | --- | --- | --- | --- |
| `auth.users` | Supabase Auth | `external` | Authentication & Session | account id、email、email confirmed state；认证凭据不复制到 public | SDK 当前会话；Authentication & Session | Supabase 托管；其他消费者只消费 `AUTH-001` |
| `profiles` | Supabase table | `implemented` | Authentication & Session | `id`=auth account id；可选 username/avatar/bio；updated at | owner-only CRUD；Authentication & Session 写注册资料 | 现有 migration；真实邮箱/确认状态仍读 Auth，Account Center 不直读本表 |
| `user_saved_locations` | Supabase table | `implemented` | Map / Location | id、user id（外键指向 auth.users，不依赖可选 profiles）、每次 create 的客户端幂等键（同账户唯一）、非空名称 ≤120、WGS84 point、created/updated at、删除标记及删除版本 | owner-only 同步读取与 CRUD；Map | Supabase 是权威；删除保留可同步的墓碑，待所有客户端已观察后再由受控维护操作清理。`20260917025814_map_saved_locations_sync.sql` 已增加同账户 `client_key` 唯一键、`version` 和 `deleted_at`；更新须匹配旧版本，墓碑不可再改，客户端无物理 DELETE grant。 |
| `user_budget_scenarios` | Supabase table | `proposed` | Cost of Living & Budget | id、user id、非空名称 ≤120、可空非负的额外生活开销/住房/交通/月净收入/家庭月度总收入、`is_current`、created/updated at；每账户最多一个 current | owner-only CRUD；Cost of Living & Budget | Account、Socio-economic 与 Suitability 只消费 `COST-002`，不直接读取本表；月净收入只用于个人预算压力，家庭月度总收入只用于 Socio 收入位置，均不可互代；额外生活开销为空表示无额外开销；migration 须 additive 地加入家庭月度总收入，旧预案保持缺失而不猜测；旧 max rent/living expenses/transport allowance 只作迁移来源，完成后移除 |
| `user_assessment_preferences` | Supabase table | `proposed` | Account Center | user id 主键；safety/cost/daily convenience/transit accessibility/infrastructure 均为整数 1–10；nullable `configured_at`、updated at | owner-only CRUD；Account Center | `configured_at is null` 是未配置，五项默认 `5` 仅可作表单预填；一次成功确认完整五项才写入时间并发布 `ACCOUNT-001` complete snapshot，后续有效修改保留它。Suitability 只消费该 Interface，不直接读取本表。migration 须 add `configured_at`，既有行保持 null，不猜测升级；字段/RLS 实现完成后才可改回 implemented。 |
| `user_ici_preferences` | Supabase table | `proposed` | Infrastructure Coverage | user id 主键；health/education/transit 整数 1–10；缺少记录的产品默认为 5；updated at | owner-only CRUD；Infrastructure | 仅保存跨设备的 last saved 权重；合法未保存 preview 是 Feature 页面内存，不写表且不发布给其他设备。已有同名表是五个 0–1 权重，不能作为本契约的 implemented 证据；migration 需迁移或替换 |
| `crowdsourced_hazards` | Supabase table | `proposed` | Hazard Reporting | id、author user id、type 五选一、trim 后标题 1–120、可空描述 ≤2000、WGS84 point、`pending/resolved`、report time | authenticated read；author-only insert/delete；author-only update 仅允许自身 `pending/resolved` 状态；Hazard、Property count | 发布后 type/title/description/location/report time 不可变；现有广泛 author-update policy 不能作为本契约的 implemented 证据，migration 须收紧为 status-only；公开不等于匿名；无 verified/rejected 或维护者例外 |
| `crowdsourced_hazard_votes` | Supabase table | `implemented` | Hazard Reporting | hazard id + user id 复合主键、vote `-1/+1`、created/updated at | authenticated 仅管理本人票；Hazard | 撤回删除本人行；级联随报告删除 |
| `hazard_vote_counts` | Supabase RPC | `proposed` | Hazard Reporting | hazard id、upvotes、downvotes；由全部 vote 行聚合，只暴露计数 | authenticated 可执行；Hazard | 受控 `SECURITY DEFINER` RPC：固定空/安全 `search_path`，RPC 内验证调用者；撤销默认与 anon execute。底层 vote 仍只允许本人读写，RPC 不返回投票者身份；migration 实现并以两账户/匿名证据验证 |
| `property_inspections` | Supabase table | `proposed` | Property Inspection | id、user id、名称 1–200、地址、必需 WGS84 point、可空收藏 id、非负价格、四项 1–5、flood evidence、notes、**原子风险快照组**（`reporting_state`、`safety_index`、`safety_source_year`、`safety_source_id`、`safety_model_boundary_version`、`safety_completeness`、`hazard_pending_count`、`hazard_radius_m`、`hazard_counted_at`、`snapshot_captured_at`）、deleted/created/updated at | owner-only CRUD；Property | 此表是该字段组的唯一字段定义。仅 `SAFETY-001` 与 `HAZARD-002` 对同一合法坐标均为完整 `available` 时，才整体 create/replace；任一不可用或 partial 时不写任何新组，已有组保持。migration 须 add–migrate–validate 必需地点及完整字段组；旧行只能在全部字段有可验证来源时迁移为完整组，否则整组保持缺失并显示风险不可用，不能猜测/补零。soft delete 不删照片 |
| `property_inspection_photos` | Supabase table | `proposed` | Property Inspection | id、inspection id、user id、唯一 storage path、可空说明 ≤1000、cover flag、created at；每实勘最多 20 | owner-only CRUD，且 user 必须拥有父实勘；Property | 现有表/部分 policy 已建立，但 update/delete 尚未完整证明父实勘 owner；删除封面回退规则归 Feature |
| `inspection-photos` | private Storage bucket | `proposed` | Property Inspection | 对象路径首段 account id，继而 inspection id 与不可变 photo id；静态常见图片、压缩后上传 | owner-only select/insert/update/delete，且父实勘同 owner；Property | 现有 bucket 已建立，但 read/update/delete 仍须按父实勘关系加固；upsert 需 read/insert/update 权限 |

### 公共政府镜像与边界对象

每张镜像表由维护者一次性导入；业务列、字段类型和键与对应官方数据集一致。客户端无写 grant。`source_dataset`、`imported_at` 等辅助元数据只能放在独立导入登记对象，不改变镜像业务列。

| 对象 / 官方数据集 | 状态 | Owner | 业务键与字段 | 消费者 / 当前实现说明 |
| --- | --- | --- | --- | --- |
| `cpi_headline_inflation` | `implemented` | Home | `(date, division)`；inflation yoy/mom | Home；现有 `cpi_core` 只有 index，不能替代 |
| `lfs_month_sa` | `implemented` | Home | `date`；employed、unemployment rate、participation rate | Home；官方六列 canonical mirror；原扩展列完整保留在客户端无访问权的 `lfs_month_sa_legacy`，不参与读取 |
| `economic_indicators` | `implemented` | Home | `date`；leading、leading diffusion | Home；当前缺失 |
| `gdp_qtr_real_sa` | `implemented` | Home | `(series, date)`；value | Home；现有年度 GDP/GNI 表不能替代季度季调序列 |
| `hh_income` | `implemented` | Home | `date`；income mean/median | Home |
| `price_catcher` / `pricecatcher` | `implemented` | Cost | `(date, premise_code, item_code)`；price | Cost；物理名可保留，来源 ID 仍为 `pricecatcher` |
| `lookup_item` | `implemented` | Cost | `item_code`；item、unit、group、category | Cost |
| `lookup_premise` | `implemented` | Cost | `premise_code`；premise/address/type/state/district | Cost |
| `cpi_state` | `implemented` | Cost | `(state, date, division)`；index；临时换算同时读取地点所属州与全国 Headline/Overall CPI 的同月记录 | Cost |
| `cpi_state_inflation` | `proposed` | Cost | `(state, date, division)`；inflation yoy/mom | Cost；当前缺失 |
| `hh_income_district` | `implemented` | Cost、Socio | `(state, district, date)`；income mean/median | Cost、Socio |
| `hh_income_state` | `proposed` | Socio | `(state, date)`；income mean/median | Socio；现有 `hies_state` 不是同一数据集 |
| `hh_inequality_district` | `implemented` | Socio | `(state, district, date)`；gini | Socio |
| `hh_inequality_state` | `proposed` | Socio | `(state, date)`；gini | Socio；现有全国 `hh_inequality` 不能替代 |
| `hies_state_percentile` | `proposed` | Socio | `(date, state, percentile, variable)`；income；P1–P100 | Socio；现有全国 percentile 与州汇总表不能替代 |
| `crime_district` | `proposed` | Crime & Security | `(date, state, police district, category, type)`；crimes | Crime；按 `state` 聚合为州级结果，现有 `crime_stats` 须验证数据集与键后迁移/重命名 |
| `government_dataset_imports` | `implemented` | Geographic Context | `(dataset id, source version, derived geometry hash)`；source URL/SHA-256、transform、row count、import time | 行政区边界的不可变导入审计；客户端无表读权 |
| `administrative_district_boundaries` | `implemented` | Geographic Context | `(boundary id, source version, derived geometry hash)`；state、district、multipolygon | 160 个 DOSM `administrative_2_district` 边界已导入；7 个退化环按 `RISK-GEO-02` 修复，重叠保持候选；客户端无表读权 |
| `police_districts_boundary` | `retiring` | 无 | id、name、state、multipolygon、source version | 禁止新消费者；警区多边形资料不可获取，待无消费者后由 migration 删除；历史 migration 不回写 |
| `hh_access_amenities` | `implemented` | Infrastructure | `(state, district, date)`；piped water、sanitation、electricity | Infrastructure |
| `hospital_beds` | `implemented` | Infrastructure | `(state, district, date, type)`；beds | Infrastructure |
| `population_district` | `proposed` | Infrastructure | `(state, district, date, sex, age, ethnicity)`；population | Infrastructure；现有 `district_population` 缺维度，不能替代 |
| `schools_district` | `proposed` | Infrastructure | `(state, district, date, stage, type)`；schools | Infrastructure；当前缺失 |
| `teachers_district` | `implemented` | Infrastructure | `(state, district, date, stage, sex)`；teachers | Infrastructure |
| `enrolment_school_district` | `implemented` | Infrastructure | `(state, district, date, stage, sex)`；students | Infrastructure |

### 标准化 GTFS 对象

原始 ZIP 不作为 Flutter 查询对象。维护者为每次尝试保留来源、采集和解析状态；站点/路线键始终包含 feed id。

| 对象 | 类型/状态 | Owner | 字段契约 | 访问规则 / 迁移方向 |
| --- | --- | --- | --- | --- |
| `gtfs_feed_snapshots` | Supabase table / `proposed` | Public Transportation | feed id、source id/url、captured at、parse status、service date range、failure reason；每次采集唯一标识 | authenticated read-only；保留失败尝试，不伪装空 feed；资料状态规则见公共交通事实源 |
| `gtfs_stops` | Supabase table / `proposed` | Public Transportation | snapshot/feed/stop id、name、WGS84 point、location type、parent station | authenticated read-only；取代缺 feed id 的 `transit_stops` |
| `gtfs_routes` | Supabase table / `proposed` | Public Transportation | snapshot/feed/route id、short name、route type | authenticated read-only |
| `gtfs_stop_services` | Supabase table / `proposed` | Public Transportation | snapshot、feed、stop、route、service date、active flag；键可证明有效路线关联 | authenticated read-only；来源链为 routes→trips→stop_times→calendar/exception |
| `transit_analysis_results` | Supabase View/RPC / `proposed` | Public Transportation | analysis point/radius/date、feed status、nearest distance、unique stops/routes、density、percentiles、score、availability、service outcome、stale warning、generated at | authenticated read-only；Transit 的稳定读取结果；完整资料状态语义见公共交通事实源 |
| `transit_reference_grid` | Supabase table / `proposed` | Public Transportation | snapshot、1 km grid point、stop density、route count、percentiles | authenticated read-only；固定参照组，不依赖用户地点 |

### 稳定公共读取对象

Flutter 不直接查询上述镜像表。每个对象只暴露 Feature 所需字段、原始统计日期、来源 ID、资料完整性和导入批次；View 使用调用者权限。RPC 默认不以提权掩盖访问错误；`read_administrative_boundary_candidates` 是已审计的例外：它只向 authenticated 返回固定候选与来源事实，表本身不授予客户端读权。

| 对象 | 类型/状态 | Owner | 覆盖数据 | 消费者 |
| --- | --- | --- | --- | --- |
| `read_home_metrics` | security-invoker RPC / `implemented` | Home | 五个 Home 数据集 | Home |
| `read_cost_inputs` | security-invoker View/RPC / `proposed` | Cost | PriceCatcher、lookup、行政区收入，以及地点所属州与全国的 Headline/Overall CPI 同月输入 | Cost |
| `read_administrative_boundary_candidates` | authenticated-only security-definer RPC / `implemented` | Geographic Context | 行政区边界候选及导入来源/版本事实 | Geographic Context；零/一/多候选的业务分类仍归 `GEO-001` |
| `read_safety_inputs` | security-invoker View/RPC / `proposed` | Crime | crime district；边界经 Geo Interface | Crime |
| `read_socio_inputs` | security-invoker View/RPC / `proposed` | Socio | income/inequality/percentile | Socio |
| `read_infrastructure_inputs` | security-invoker View/RPC / `proposed` | Infrastructure | amenities/beds/population/schools/teachers/enrolment | Infrastructure |
| `read_transit_analysis` | security-invoker View/RPC / `proposed` | Transit | snapshots、标准化站点/路线、参照组与聚合 | Transit |

### 本机对象

| 对象 | 类型/状态 | Owner | 字段契约 | 寿命/访问 |
| --- | --- | --- | --- | --- |
| `home_public_cache` | SQLite / `implemented` | Home | cache key、result payload/version、每项 source date、fetched at、expiry/completeness | 无账户字段；退出保留 |
| `cost_public_cache` | SQLite / `proposed` | Cost | location/admin key、model version、result、source dates、fetched at、3-day expiry/completeness | 无预案/用户输入；退出保留 |
| `crime_public_cache` | SQLite / `proposed` | Crime | reporting state、model/boundary version、result、source year、fetched at、3-day expiry | 无账户字段；退出保留 |
| `facility_public_cache` | SQLite / `proposed` | Facilities | coordinate key、2,000 m、mapping version、完整结果/归因/query time、24-hour expiry | 只保存完整成功；无收藏名称/账户 id |
| `saved_location_cache` | SQLite logical partition / `implemented` | Map | account id、remote id、name、point、remote version/timestamps、删除标记、sync state | 同账户 opened scope；退出清除；墓碑仅用于同步，不作为用户可见收藏 |
| `saved_location_create_queue` | SQLite logical partition / `implemented` | Map | account id、client id/idempotency key、name、point、created at、attempt/retry state/error class | 只排队 create；成功变 cache 行；退出清除未同步项 |
| `property_drafts` | SQLite / `proposed` | Property | account id、draft id、全部表单字段、location、updated at | 同账户 scope；远端记录创建成功后按流程清除；草稿照片由独立对象拥有 |
| `property_draft_photos` | SQLite / `proposed` | Property | account id、draft id、本机照片副本引用、说明、cover 标记、created at | 仅同账户 opened scope 可读写；跨重启保留。远端 inspection 成功创建后才分配正式 photo/inspection 标识并转入 `property_photo_upload_queue`；全部转换成功前保留草稿照片记录和本机副本，转换失败保留重试；退出/换号清除。本机 schema migration 须新增此对象，不从旧 mock/相册原件猜测照片资料 |
| `property_photo_upload_queue` | SQLite / `proposed` | Property | account/inspection/photo id、local file ref、target path、attempt/retry/error/upload state | 只接收已有同账户远端 inspection 的正式照片待传项；与应用数据文件同生；成功后删本机文件/queue；退出清除 |
| `device_preferences` | key-value / `proposed` | Application Shell | locale 与小型无身份 UI 偏好 | 跨重启/账户保留；不放业务记录 |

## 已弃用或不适配对象

| 对象 | 状态 | 原因 | 替代/处理 |
| --- | --- | --- | --- |
| `user_saved_regions` | `deprecated` | 将坐标误建模为行政区 id | 仅有可证明历史坐标时迁移到 `user_saved_locations`；否则不可猜测转换；新代码无权访问 |
| `user_property_inspections` | `deprecated` | JSON/图片 URL 形状不满足实勘、照片与风险生命周期 | 仅经显式数据审计后迁移到 normalized 对象；当前 API deny |
| `cpi_core`、`lfs_month`、`gdp_gni_annual_real`、`district_population`、`hies_malaysia_percentile`、`hies_state`、`transit_stops` | `deprecated` for new design | 名称/粒度/字段不能证明满足 approved product dataset | 保留直至导入审计；消费者只接稳定读取对象，不直接兼容 |
| `get_district_income_rank`、`get_district_prices`、`get_transit_density`、`match_police_district` | `deprecated` for new design | 旧签名不足以携带来源、版本、完整性与新领域语义 | 由 owning Feature 的稳定读取对象取代；确认无消费者后 remove |

## 通用访问与迁移规则

1. 暴露 schema 的 table/View/RPC 同时登记显式 grant、RLS/调用者权限和 allow/deny 测试；私有 `UPDATE` 同时保护原 owner 与新 owner，且有对应 SELECT 权限。
2. 公开只表示所有已认证应用用户可读，不表示匿名可读或任意用户可写。客户端只能使用 publishable/anon key，不能持有 service-role。
3. View 使用调用者权限；必须提权的 RPC 留在非暴露 schema、显式撤销默认执行权、内部校验账户，并由项目负责人逐项批准。
4. Storage 文件与照片元数据不是原子对象。失败时保留可重试 queue；孤儿清理只处理可证明属于当前账户且无有效元数据的目标。
5. 基线后的 schema 演进使用 add–migrate–remove：先添加新对象并验证双读/迁移，再切换消费者，最后经项目负责人批准移除旧对象。不得从行政区 id 猜坐标或从 fixture 制造迁移值。
6. 示例只用清洗数据；迁移、测试和日志不得记录凭据、token、service-role key、真实邮箱、自由文字、照片或可识别精确地点。
7. 本地 Supabase 使用仓库锁定的 CLI `2.117.0`，`config.toml` 设置 `auto_expose_new_tables = false`；远端只接受与 migration history 一致的 forward migration，不修改已应用历史或执行 history repair。
8. 遗留 `public` PostGIS 的 Data API 补偿控制由 `RISK-DATA-API-01` 定义：当前应用禁用 GraphQL，并拒绝 `spatial_ref_sys` / `st_estimatedextent` 路径。新增表/View/RPC 仍须自行满足第 1–3 条，不能依赖 pre-request hook 代替 RLS。

## Home Wave 4 实现与校验证据（2026-09-17）

`read_home_metrics()` 是无参数、stable、security-invoker、空 search_path 的只读 RPC。
结果固定为 `{"version":1,"datasets":{...}}`，五个 dataset ID 始终存在并映射到数组；空导入返回空数组。
CPI 投影 `date/division/inflation_yoy/inflation_mom`，仅四个模型 division；
劳动力投影 `date/lf_employed/u_rate/p_rate`；经济指标投影 `date/leading/leading_diffusion`；
GDP 投影 `date/series/value`，仅 `growth_qoq`；收入投影 `date/income_median`。
日期为原统计日期，RPC 不加入账户、地点或导入日期。authenticated 有 execute/源表 select；
PUBLIC/anon 无 execute，anon/authenticated 无源表写 grant；受控导入的 service_role 权限不进入 Flutter。

SQLite `home_public_cache` migration 在 Data Adapter 懒初始化，字段为
`cache_key`（national 主键）、`payload_version`、`result_payload`（仅公开快照）、
`source_dates`、`fetched_at`、`expires_at`、`completeness`。版本 1；TTL 24 小时；
无账户、地点或队列字段；退出保留，冷却不序列化。

Forward migrations：`add_home_metrics_read_rpc`、`grant_home_dataset_maintenance`、
`allow_maintenance_data_api_guard`、`harden_home_mirror_readonly`、`align_official_lfs_mirror`。
维护者与客户端均运行既有 private pre-request guard；无新的 security-definer 路径。
劳动力对齐是 add–migrate，原八列表及数据完整保留在 legacy 对象，不执行 remove。

官方 CSV 的 schema、业务键、行数、最大日期与 SHA-256 审计见 Home Wave 4 验收证据。
四个本期镜像分别导入 7812 / 198 / 426 / 46 行；最大日期分别为
2026-07-01 / 2026-06-01 / 2026-06-01 / 2026-04-01；收入已有 22 行，最大日期 2024-01-01。
当前官方 GDP 文件只有 abs，故 RPC 的 growth_qoq 数组为空；这是缺少评分输入，
不能从 abs 制造增长。经济动能剩余 70% 原权重按模型归一化；完整/部分/空数组由确定性测试验证。

## Map / Location 运行时读取契约（Wave 4）

- `read_saved_locations()`：`security invoker`，仅 authenticated EXECUTE；底层 owner-only SELECT RLS。返回 `id` UUID、`client_key` text、`name` text、`latitude`/`longitude` float8、`created_at`/`deleted_at` timestamptz、`version` bigint。包含墓碑；客户端只向用户展示非墓碑项。
- create 使用 `user_saved_locations` 的 `user_id,client_key` ignore-duplicates upsert，`location` 为 SRID=4326 的 Point。既有幂等键不会更新或复活墓碑；删除通过匹配 `id,version,deleted_at is null` 更新 `deleted_at`。
- Map 的最终范围验证只读取 `read_administrative_boundary_candidates(latitude, longitude)` 并检查导入版本/hash；以是否存在 ST_Covers 候选判断联合范围，不选择或返回行政区事实。
- SQLite 当前存储 Adapter 将 cache 与 create queue 合并到独占物理表 `map_saved_records(account_id,client_key,payload)`；payload 保存收藏字段、远端版本、墓碑、sync state，以及持久化 attempts / last_failure（重试次数与类型化错误类别）。`saved_location_cache`、`saved_location_create_queue` 为该表的两类逻辑记录，分别按 synchronized 与 queued/retryableFailure 区分。读、替换和清理均按 account_id，替换在单个 SQLite transaction 完成。

- `20260917031216_saved_locations_optional_profile.sql` 先增设并验证 auth.users 外键，再移除 profiles 外键；已有记录不重写，账户权限不变。无可选 profile 的已确认账户已通过真实收藏创建验收。
