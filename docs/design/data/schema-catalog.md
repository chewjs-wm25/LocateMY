# Schema Catalog

> 状态：Issue #31 精简修订；历史 migration 保留，目标与现有实现分别标注。
> 最后更新：2026-09-18

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
| `auth.users` | Supabase Auth | `external` | Authentication & Session | account id、email（确认信息留在 SDK，不展示验证界面）；认证凭据不复制到 public | SDK 当前会话；Authentication & Session | Supabase 托管；其他消费者只消费 `AUTH-001` |
| `profiles` | Supabase table | `implemented` | Authentication & Session | `id`=auth account id；可选 username/avatar/bio；updated at | owner-only CRUD；Authentication & Session 写注册资料 | 现有 migration；真实邮箱读 Auth，Account Center 不直读本表 |
| `user_saved_locations` | Supabase table | `implemented` | Map / Location | id、user id（auth.users 外键）、同账号唯一 client_key、名称 1–120、WGS84 point、created/updated at；兼容保留 deleted_at/version | owner-only 在线读取／CRUD；Map | Supabase 权威，无本机缓存／队列；沿用现有在线 soft delete 和版本检查以兼容已部署 API，不向 Flutter 发布同步状态。新读取 RPC 过滤已删记录，客户端不回放墓碑。 |
| `user_budget_scenarios` | Supabase table | `implemented` | Cost of Living & Budget | id、user id、非空名称 ≤120、可空非负的额外生活开销/住房/交通/月净收入/家庭月度总收入、`is_current`、created/updated at；每账户最多一个 current | owner-only CRUD；Cost of Living & Budget | Account 与 Socio-economic 只消费 `COST-002`，不直接读取本表；月净收入只用于个人预算压力，家庭月度总收入只用于 Socio 收入位置，均不可互代；额外生活开销为空表示无额外开销；20260917151921已additive加入家庭收入；20260917164939 FK改auth.users、writer列授权与原子current切换；旧金额列只作已完成迁移来源，非破坏性保留归档且无客户端写授权，不被新接口消费 |
| `user_assessment_preferences` | Supabase table | `deprecated` | 无新消费者 | 历史五项偏好数据 | 客户端停止使用 | Issue #31 向前 migration 撤销 anon/authenticated 所有 grant；不删除历史数据，不建立替代五偏好接口。 |
| `user_ici_preferences` | Supabase table | `implemented` | Infrastructure Coverage | user id 主键；health/education/transit 整数 1–10；缺少记录的产品默认为 5；updated at | owner-only CRUD；Infrastructure | 仅保存跨设备的 last saved 权重；合法未保存 preview 是 Feature 页面内存，不写表且不发布给其他设备。20260917161435 additive 加入三个整数列，旧记录目标值5；历史五个0–1列保留但客户端无列权限；外键转auth.users，既有owner-only RLS保留；20260917161729补齐PostgREST upsert列grant |
| `crowdsourced_hazards` | Supabase table | `implemented` | Hazard Reporting | id、author user id（外键指向 auth.users，不依赖可选 profiles）、type 五选一、trim 后标题 1–120、可空描述 ≤2000、WGS84 point、`pending/resolved`、report time | authenticated read；author-only insert/delete；author-only update 仅允许自身 `pending/resolved` 状态；Hazard、Property count | 发布后 type/title/description/location/report time 不可变；现有广泛 author-update policy 不能作为本契约的 implemented 证据，migration 须收紧为 status-only；公开不等于匿名；无 verified/rejected 或维护者例外 |
| `crowdsourced_hazard_votes` | Supabase table | `implemented` | Hazard Reporting | hazard id + user id（外键指向 auth.users，不依赖可选 profiles）复合主键、vote `-1/+1`、created/updated at | authenticated 仅管理本人票；Hazard | 撤回删除本人行；级联随报告删除 |
| `hazard_vote_counts` | Supabase RPC | `implemented` | Hazard Reporting | hazard id、upvotes、downvotes；由全部 vote 行聚合，只暴露计数 | authenticated 可执行；Hazard | 受控 `SECURITY DEFINER` RPC：固定空/安全 `search_path`，RPC 内验证调用者；撤销默认与 anon execute。底层 vote 仍只允许本人读写，RPC 不返回投票者身份；migration 实现并以两账户/匿名证据验证 |
| `property_inspections` | Supabase table | `implemented` | Property Inspection | id、user id（auth.users 外键）、名称 1–200、地址、WGS84 point（新写入／更新必需且经纬度合法）、可空收藏 id、非负价格、四项 1–5、flood evidence、notes；风险组 `snapshot_availability`（available/unavailable）、`snapshot_latitude/longitude`、`reporting_state`、`safety_index`、`safety_source_year`、`safety_source_id`、`safety_model_boundary_version`、`safety_completeness`、`hazard_pending_count`、`hazard_radius_m`、`hazard_counted_at`、`snapshot_captured_at`；deleted/created/updated at | authenticated owner-only 在线 CRUD；anon deny | 20260917173933 已对齐风险组、auth.users FK 与地点约束。available 必须整组完整、安全 complete、radius=2000、快照坐标匹配实勘；unavailable 的业务风险组整体为空，可保留尝试时间。坐标变化且无匹配新组时 trigger 清旧组；普通编辑／详情／重启不重算。NOT VALID 地点约束保留历史空地点，读取 RPC 不发布空地点记录；不猜测 backfill。旧 risk_police_district 等保留但新接口不消费。软删除仅设 deleted_at，保留照片；永久删除生命周期见下文。 |
| `property_inspection_photos` | Supabase table | `implemented` | Property Inspection | id、inspection id（父实勘外键，on delete cascade）、user id（auth.users 外键）、唯一 storage path、可空说明 ≤1000、cover flag、`upload_complete`（非空 boolean；旧行默认 true，正式预留新行 false）、created at；每实勘包括未完成预留在内最多 20；每父实勘最多一个 cover | authenticated owner-only CRUD，所有操作检查本人照片与本人父实勘；anon deny；Property | 20260917173933 已加固 RLS、身份／路径／created_at 不可变 guard、父行锁20张限制与路径校验。路径为 account id/inspection id/photo id.jpg，必须先有正式父实勘；上传成功后 finish RPC 才标完成。20260917174617 删除封面 trigger 选择最早完成照片（created_at、id）回退。未完成元数据保留正式 path，不能作为成功照片展示；软删／恢复保留所有元数据。 |
| `inspection-photos` | private Storage bucket | `implemented` | Property Inspection | 正式对象路径 account id/inspection id/photo id.jpg；bucket 上限 10 MiB，允许 JPEG/PNG/WebP/HEIC；Feature 将支持的静态照片压缩为 JPEG 后上传 | authenticated owner-only select/insert/update/delete；read/delete 要求路径 account 与本人父实勘；insert/update 还要求父实勘活动且已有对应 metadata path；anon deny；Property | 20260917173933 已按父实勘关系加固全部 Storage policy，upsert read/insert/update 受同一规则限制。软删除仍可读取本人照片且禁止写入，恢复后可写。永久清空先移除文件，再删 metadata／parent；实际 SDK 重复删除已不存在文件成功，权限／网络失败不吞掉。 |

### Property 在线照片 API 与删除生命周期

| 对象 | 类型/状态 | Owner | 字段与权限 |
| --- | --- | --- | --- |
| `read_property_inspections(uuid, boolean)` | security-invoker RPC / `implemented` | Property B | 可选实勘 id 与 deleted 筛选（默认活动；null 包括已删）；仅本人且 location 非空，返回 JSON 与 latitude/longitude；updated_at、id 降序。 |
| `reserve_property_photo(uuid)` | security-invoker RPC / `implemented` | Property B | 锁定本人活动父实勘，生成正式 photo id/path 并写 upload_complete=false，返回元数据；20张检查计入预留行。 |
| `finish_property_photo(uuid)` | security-invoker RPC / `implemented` | Property B | 锁定本人活动父实勘，将本人照片 upload_complete=true；无封面时设为封面。应用只在 Storage 上传成功后调用，不以预留元数据冒充上传成功。 |
| `edit_property_photo(uuid, uuid, text, boolean)` | security-invoker RPC / `implemented` | Property B | 本人活动父实勘与已完成照片；编辑说明／原子切换单封面，父行锁与唯一 cover 索引共同生效。 |

迁移 `20260917173933_property_online_photos_and_risk.sql` 与 `20260917174617_property_cover_fallback.sql` 已部署开发 Supabase。四个公开 RPC 固定空 search_path、撤销 PUBLIC/anon EXECUTE，仅 authenticated 可执行并受表 RLS 约束；内部触发函数撤销客户端执行。真实 owner CRUD、其他账户与匿名 deny、Storage 上传／读取、软删／恢复与永久清空证据见 Wave 6 验收。

软删除／恢复仅变更父实勘 deleted_at，文件与元数据保留。确认取消不执行删除。确认永久清空后，应用按每份实勘逐个执行 Storage 文件删除 → 对应照片 metadata 删除 → 全部照片处理成功后 parent 删除；文件已不存在允许继续，其他失败保留未完成 path 与父记录供当前页重试，不先利用 cascade 清空元数据。上传／元数据完成失败同样保留正式 path 与 upload_complete=false；当前页内存可重试原照片，离页后可重新选择，不建立数据库上传队列或本机持久队列。

### Cost/Budget 固定导入与原子写API

| 对象 | 类型/状态 | Owner | 字段与权限 |
| --- | --- | --- | --- |
| `cost_basket_baseline` | 自有冻结表 / implemented | Cost B | basket_version+item_code主键；quantity、name、unit、expected_unit、national_price可空、source_date。固定导入全国商户双中位数逐月代表价平均，不随客户端时钟变化。RLS authenticated只读，无客户端写入；缺失全国价保留null，不重算剩余权重冒充完整基准。20260917164939建立；当前272/1541/1645全部原始观测0行，基准不完整。 |
| `select_current_budget(uuid)` | security-invoker RPC / implemented | Cost B | auth.uid账户事务锁；归属检查后取消旧current并设置所选，返回完整saved行；不归属/不存在返回null不更改current。默认PUBLIC/anon执行撤销，authenticated执行；底表owner-only RLS与唯一current索引继续生效。 |

### 公共政府镜像与边界对象

每张镜像表由维护者一次性导入；业务列、字段类型和键与对应官方数据集一致。客户端无写 grant。`source_dataset`、`imported_at` 等辅助元数据只能放在独立导入登记对象，不改变镜像业务列。

| 对象 / 官方数据集 | 状态 | Owner | 业务键与字段 | 消费者 / 当前实现说明 |
| --- | --- | --- | --- | --- |
| `cpi_headline_inflation` | `implemented` | Home | `(date, division)`；inflation yoy/mom | Home；现有 `cpi_core` 只有 index，不能替代 |
| `lfs_month_sa` | `implemented` | Home | `date`；employed、unemployment rate、participation rate | Home；官方六列 canonical mirror；原扩展列完整保留在客户端无访问权的 `lfs_month_sa_legacy`，不参与读取 |
| `economic_indicators` | `implemented` | Home | `date`；leading、leading diffusion | Home；当前缺失 |
| `gdp_qtr_real_sa` | `implemented` | Home | `(series, date)`；value | Home；现有年度 GDP/GNI 表不能替代季度季调序列 |
| `hh_income` | `implemented` | Home | `date`；income mean/median | Home |
| `price_catcher` / `pricecatcher` | `implemented` | Cost | `(date, premise_code, item_code)`；price | Cost；2026-09-17 确认仅保留 cost-basket-v1 的 11 个商品代码，2025-10 至 2026-09 共 460,019 行；来源 ID 为 pricecatcher；原始观测缺失保持缺失 |
| `lookup_item` | `implemented` | Cost | `item_code`；item、unit、group、category | Cost |
| `lookup_premise` | `implemented` | Cost | `premise_code`；premise/address/type/state/district | Cost |
| `cpi_state` | `implemented` | Cost | `(state, date, division)`；index；临时换算同时读取地点所属州与全国 Headline/Overall CPI 的同月记录 | Cost |
| `cpi_state_inflation` | `proposed` | Cost | `(state, date, division)`；inflation yoy/mom | Cost；当前缺失 |
| `hh_income_district` | `implemented` | Cost、Socio | `(state, district, date)`；income mean/median | Cost、Socio |
| `hh_income_state` | `implemented` | Socio | `(state, date)`；income mean/median | Socio；现有 `hies_state` 不是同一数据集 |
| `hh_inequality_district` | `implemented` | Socio | `(state, district, date)`；gini | Socio |
| `hh_inequality_state` | `implemented` | Socio | `(state, date)`；gini | Socio；2026-09-17 完整导入 289 行，最新 2024 年覆盖 16 州；不代表 Socio Feature 已实现 |
| `hies_state_percentile` | `implemented` | Socio | `(date, state, percentile, variable)`；income；P1–P100 | Socio；2026-09-17 完整导入 19,200 行，2019/2022/2024 × 16 州 × 100 百分位 × 4 变量；保留 96 个官方隐私空值 |
| `crime_district` | `implemented` | Crime & Security | `(date, state, police district, category, type)`；crimes | Crime；已重命名并与官方 CSV 完整业务内容校验；只读 RPC 排除全国/All 汇总，聚合警区叶记录 |
| `government_dataset_imports` | `implemented` | Geographic Context | `(dataset id, source version, derived geometry hash)`；source URL/SHA-256、transform、row count、import time | 行政区边界的不可变导入审计；客户端无表读权 |
| `government_data_import_files` | `implemented` | 手动资料导入 | `(import_id,dataset_id,source_sha256)`；source_url、selection_rule、row_count、rejected_rows、imported_at | 33 个源文件登记；单独记录 PriceCatcher 筛选和关丹归档下载 URL；RLS 无客户端 policy/grant，service_role 仅 SELECT/INSERT/UPDATE |
| `administrative_district_boundaries` | `implemented` | Geographic Context | `(boundary id, source version, derived geometry hash)`；state、district、multipolygon | 160 个 DOSM `administrative_2_district` 边界已导入；7 个退化环按 `RISK-GEO-02` 修复，重叠保持候选；客户端无表读权 |
| `police_districts_boundary` | `retiring` | 无 | id、name、state、multipolygon、source version | 禁止新消费者；警区多边形资料不可获取，待无消费者后由 migration 删除；历史 migration 不回写 |
| `hh_access_amenities` | `implemented` | Infrastructure | `(state, district, date)`；piped water、sanitation、electricity | Infrastructure |
| `hospital_beds` | `implemented` | Infrastructure | `(state, district, date, type)`；beds | Infrastructure |
| `population_district` | `implemented` | Infrastructure | `(state, district, date, sex, age, ethnicity)`；population | Infrastructure；2026-09-17 完整导入 383,040 行，2020–2025 每年 160 行政区 × 3 性别 × 19 年龄 × 7 族群；population 保留官方千人单位 |
| `schools_district` | `implemented` | Infrastructure | `(state, district, date, stage, type)`；schools | Infrastructure；实际已导入，组成年份仍须检查 |
| `teachers_district` | `implemented` | Infrastructure | `(state, district, date, stage, sex)`；teachers | Infrastructure |
| `enrolment_school_district` | `implemented` | Infrastructure | `(state, district, date, stage, sex)`；students | Infrastructure |

### 标准化 GTFS 对象

原始 ZIP 不作为 Flutter 查询对象。维护者为每次尝试保留来源、采集和解析状态；站点/路线键始终包含 feed id。

| 对象 | 类型/状态 | Owner | 字段契约 | 访问规则 / 迁移方向 |
| --- | --- | --- | --- | --- |
| `gtfs_feed_snapshots` | Supabase table / `implemented` | Public Transportation | `(snapshot_id,feed_id)` 主键；source id/url、captured at、parse status、service start/end、failure reason、source SHA256 | authenticated read-only；usable 必须有采集时间及有序服务日期；失败尝试保留 |
| `gtfs_stops` | Supabase table / `implemented` | Public Transportation | `(snapshot_id,feed_id,stop_id)` 主键；name、WGS84 point、location type、parent station、normalized station type；PostGIS geography/GiST | authenticated read-only；只统计 location type 0；取代缺 feed id 的 `transit_stops` |
| `gtfs_routes` | Supabase table / `implemented` | Public Transportation | `(snapshot_id,feed_id,route_id)` 主键；short name、raw route type | authenticated read-only；RPC 站点 routes 保留原始类型及 service active |
| `gtfs_service_dates` | Supabase table / `implemented` | Public Transportation | `(snapshot_id,feed_id,service_date,service_id)` 主键；active | authenticated read-only；calendar 按星期展开，再覆盖 calendar_dates exception |
| `gtfs_stop_service_links` | Supabase table / `implemented` | Public Transportation | `(snapshot_id,feed_id,stop_id,route_id,service_id)` 主键；外键指向 stop/route | authenticated read-only；来源链 routes→trips→stop_times→calendar/exception |
| `gtfs_stop_services` | security-invoker view / `implemented` | Public Transportation | snapshot、feed、stop、route、service date、active flag | authenticated read-only；由 links/date 聚合，保留日期有效路线关联 |
| `transit_analysis_results` | security-invoker view / `implemented` | Public Transportation | promoted grid point/date、canonical RPC result JSON 及 density/routes；只读维护者检查视图 | authenticated read-only；Flutter 只调用参数化 RPC，不读此视图 |
| `transit_reference_grid` | Supabase table / `implemented`；正式网格已准备 | Public Transportation | `(snapshot_id,analysis_date,grid_id)` 主键；grid version、1 km grid point、stop density、route count | authenticated read-only；固定参照组，不依赖用户地点；范围为可用 feed 的 location_type=0 站点 1.5 km 圆并集；正式网格方法见下文 |
| `transit_evaluation_batches` | Supabase table / `implemented` | Public Transportation | snapshot 主键、grid version、promotion time、expected count 固定 16 | authenticated read-only；维护者在导入成功后显式推广；应用不导入或推广 |

迁移：`20260917051623_public_transportation_analysis.sql`、`20260917053457_transit_source_validation.sql`、`20260917053658_transit_canonical_result_view.sql`、`20260917054002_transit_missing_batch_sources.sql`、`20260917062031_transit_missing_source_identity.sql`；已应用本地及开发 Supabase。全部基础表启用 RLS，authenticated 仅 SELECT 且需非空 `auth.uid()`；anon 无读权限，authenticated/anon 无写权限。RPC 为 security invoker，固定空 search path，匿名无 EXECUTE。

`read_transit_analysis` 固定登记产品预期的 16 个官方 feed，左连接所选 snapshot；缺行仍返回独立 missing 状态及官方来源，不伪装空 feed。partial 保留成功站点但不评分。正式全资料评分仍需已准备的同 snapshot/date/grid 参照组；无 grid 则 source unverifiable。现有 `official-2026-09-17` 为 15 usable + 1 failed 的 partial batch，此实际来源不产生完整分数。完整评分函数已在真实开发 Supabase 的 authenticated 角色下用受控算例验证为 75，事务 rollback；不得把该算例描述成官方全资料结果。

正式 `official-2026-09-17` / `2026-09-17` 参照组已有 9,641 点，版本 `utm-wgs84-1km-stopcatchment-v1`。方法：UTM WGS84 EPSG:32647–32651，固定原点 `(0,0)`；1,000 m 单元中心 `(i+0.5,j+0.5)*1000`，按中心所在经度分区裁剪以避免 zone 重叠；grid ID 为 `zone:i:j`。中心须满足可用 feed 站点的 1,500 m geography 距离条件；密度为圈内唯一 `(feed_id,stop_id)` 数除以 `π×2.25 km²`，路线为分析日期 active 的唯一 `(feed_id,route_id)` 数。参照组绑定 snapshot/date/method，不随用户地点变化。生成方法使用 [PostGIS ST_SquareGrid](https://postgis.net/docs/ST_SquareGrid.html) 的固定米制网格与 [ST_DWithin](https://postgis.net/docs/ST_DWithin.html) 的 geography 米制距离。

维护脚本 `tool/prepare_transit_reference_grid.py` 核对源 ZIP hash 和五张标准化表，记录输入/grid hash、zone 分布与完整性；远端核验服务范围外点、非正密度和负路线数均为 0。上传可安全续传，既有不同记录拒绝替换；完整 batch promotion 核对整个审计网格而非仅一条记录。与真实来源登记分开保存受控算例证据。

真实读取/allow-deny及代码版本证据见 [公共交通 Wave 5 验证报告](../../human/evidence/public-transportation-wave5-2026-09-17/report.md)。表结构 implemented 不表示 Feature 达到 `Implemented`。

### 稳定公共读取对象

2026-09-17 手动资料补齐后，最新推广交通批次为 `manual-2026-09-17-complete`：16 feed usable、17,611 站点、452 路线与 10,271 个重新核验的固定参照网格点（分析日期 2026-09-17）。关丹官方 producer URL 与真实归档下载 URL 分别保留在快照身份和 `government_data_import_files` 审计中，采集来源为 2026-07-23 归档。正式 Flutter 读取服务、完整评分、日期超界和读写权限 live 验证通过；旧部分批次仍保留。导入结果见 `docs/human/government-data-import-result-2026-09-17.md`，此前的部分批次说明仅描述旧批次。

Flutter 不直接查询上述镜像表。每个对象只暴露 Feature 所需字段、原始统计日期、来源 ID、资料完整性和导入批次；View 使用调用者权限。RPC 默认不以提权掩盖访问错误；`read_administrative_boundary_candidates` 是已审计的例外：它只向 authenticated 返回固定候选与来源事实，表本身不授予客户端读权。

| 对象 | 类型/状态 | Owner | 覆盖数据 | 消费者 |
| --- | --- | --- | --- | --- |
| `read_home_metrics` | security-invoker RPC / `implemented` | Home | 五个 Home 数据集 | Home |
| `read_cost_inputs` | security-invoker RPC / `implemented` | Cost | 固定11项基准、12月窗口商户双中位数价格/月份/观测计数、行政区月家庭收入中位数、同最新共同月份州/全国overall CPI（当前无全国headline，合法null，不用core代替） | Cost；20260917164939与20260917165427必要索引，authenticated只读 |
| `read_administrative_boundary_candidates` | authenticated-only security-definer RPC / `implemented` | Geographic Context | 行政区边界候选及导入来源/版本事实 | Geographic Context；零/一/多候选的业务分类仍归 `GEO-001` |
| `read_safety_inputs` | security-invoker RPC / `implemented` | Crime | crime district；边界经 Geo Interface | Crime |
| `read_socio_inputs` | security-invoker RPC / `implemented` | Socio | `p_state text, p_district text default null` → JSON version/state/district、五组收入/基尼/百分位原始观测 | Socio；authenticated execute，anon/PUBLIC deny |
| `read_infrastructure_inputs` | security-invoker RPC / `implemented` | Infrastructure | p_state/p_district → version/scope、amenities/beds/population/schools/teachers/enrolment 六组原始观测；全国行政区同年百分位由应用计算 | Infrastructure；authenticated execute，PUBLIC/anon deny；20260917161435 migration |
| `read_transit_analysis` | security-invoker RPC / `implemented` | Transit | snapshots、标准化站点/路线、参照组与聚合 | Transit |

### 本机对象

| 对象 | 类型/状态 | Owner | 字段契约 | 寿命/访问 |
| --- | --- | --- | --- | --- |
| `home_public_cache` | SQLite / `implemented` | Home | cache key、result payload/version、每项 source date、fetched at、expiry/completeness | 无账户字段；退出保留 |
| `cost_public_cache` | SQLite / `implemented` | Cost | location/admin key、model version、result、source dates、fetched at、3-day expiry/completeness | 无预案/用户输入；退出保留 |
| `crime_public_cache` | SQLite / `implemented` | Crime | cache key（全国输入或分析坐标）、model version、payload（只读州输入/州与boundary version）、source year、fetched at、3-day expiry | 无账户字段；退出保留 |
| `facility_public_cache` | SQLite / `implemented` | Facilities | `coordinate_key`（坐标/2,000 m/映射版）、`radius_metres`、`mapping_version`、`payload`（完整公开 OSM 元素）、`source`、`copyright_url`、`queried_at`、`expires_at`（24h）、`complete` | 只保存完整成功；无收藏名称/账户 id；旧无元数据缓存安全失效；按当前地点重建分类结果 |





| `infrastructure_public_cache` | SQLite / `implemented` | Infrastructure | cache_key/version/payload/fetched_at/expires_at；原始公开输入及坐标地理语境，3日期限；刷新失败不续期 | 无账号／权重／地点名称；退出保留 |
| `device_preferences` | key-value / `implemented` | Application Shell | locale 与小型无身份 UI 偏好 | 跨重启/账户保留；不放业务记录 |

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

## Map / Location 在线读取契约（Issue #31）

`read_saved_locations()` 仍 security invoker、authenticated EXECUTE 与 owner-only RLS；兼容返回
id/client_key/name/latitude/longitude/created_at/deleted_at/version。新版 RPC 只返回活动收藏。
创建仍按当前账号和幂等键在线 upsert；删除按 id/version 更新 deleted_at，写入失败普通反馈。
这是兼容现有服务器字段，不再有私有 SQLite 缓存、create queue、attempt/retry state 或自动重放。
启动时移除旧 map_saved_records 表，公共 facility_public_cache 保留；退出不触发本机删除协议。
范围验证仍调用 read_administrative_boundary_candidates 并校验 provenance，不选择默认行政区。
可选 profiles 不阻塞收藏，外键仍指向 auth.users。

## Issue #31 向前 migration 与尚未交付事项

`20260917085335_simplify_online_records.sql` 撤销已排除五偏好的客户端权限，增加房产快照可用性／完整组约束、
坐标失配失效 trigger，并保持收藏 RPC 形状而过滤历史 soft delete。
不删除历史 migration／远端数据，不调整公式，不自动重算风险。
预算、三项 ICI、完整房产的 auth.users 外键、Storage 父实勘权限和地点非空仍为后续对应 Feature migration 责任。
本机新增对象是预算 JSON v1 导出（implemented，应用文件目录；Cost Feature 已通过真实文件及设备生命周期验收），格式与读取验收见 Cost 契约；退出保留，不写回云端。
不存在私有收藏缓存、房产跨重启草稿／照片待传队列或清理屏障的新 schema。

### Wave 5 Hazard Reporting 运行时 API（2026-09-17）

`20260917050950_hazard_reporting_api.sql` 实现下列 authenticated-only RPC；全部撤销
PUBLIC/anon 的 EXECUTE，固定空 search_path。上报及投票关联 Auth 账户，资料登记可跳过。
替代 Auth 外键先验证再移除 profiles 外键；公开报告不因资料删除而删除。

| RPC / 参数 | 返回 | 权限与边界 |
| --- | --- | --- |
| `hazard_create(p_type text,p_title text,p_description text,p_latitude float8,p_longitude float8)` | report JSON | 五类、trim 标题 1–120、描述 ≤2000、有效马来西亚坐标；author/report time/status/id 由服务器生成。客户端 INSERT grant 只含 user_id/type/title/description/location。 |
| `hazard_detail(p_id uuid)` | report JSON | 公共内容；author 仅 mine/other；vote 仅本人选择及聚合计数；notFound 非空对象。 |
| `hazard_page(p_mine bool,p_south float8,p_west float8,p_north float8,p_east float8,p_cursor uuid=null)` | `{reports,next_cursor}` | 每页 50，report_time/id 降序 keyset；mine 限当前账户；失效 cursor 返回错误。 |
| `hazard_status(p_id uuid,p_status text)` | report JSON | author-only pending/resolved；UPDATE grant 仅 status，trigger 保证其余发布字段不可改。 |
| `hazard_delete(p_id uuid)` | true | author-only；缺失/并发删除返回 notFound，报告投票级联删除。 |
| `hazard_vote(p_id uuid,p_vote text)` | `{mine,upvotes,downvotes}` | 本人 up/down/none 唯一票；counts 由下列 RPC 读取，不枚举他人票。 |
| `hazard_vote_counts(p_id uuid)` | `{upvotes,downvotes}` | 唯一 SECURITY DEFINER；验证 auth.uid 和报告存在，仅暴露计数，撤销匿名/default execute；替换旧本人行视图。 |
| `hazard_pending_count(p_latitude float8,p_longitude float8)` | `{count,radius_meters,counted_at,complete}` | invoker 读取公共 pending；Haversine 球半径 6,371,000m，d ≤2000m 包含边界；完整结果带 UTC 时间；`20260917053803_hazard_count_location_guard.sql` 拒绝不在马来西亚行政边界内的伪造坐标。 |

report JSON 形状为 `{id,type,title,description,latitude,longitude,status,reported_at,author,vote}`。
所有其他 RPC 使用 SECURITY INVOKER 并沿用报告/投票 RLS。原始报告列、用户身份及他人票
不通过 report JSON 暴露；原始表写入也受 column grants/RLS/immutable trigger 约束。
证据：`python3 tool/verify_hazard_live.py`，双账户、无 profile 账户、匿名 deny、内容不可变、
状态/删除、票切换/撤回及真实 Haversine 边界；见 Wave 5 验收报告。

## Wave 5 Crime & Security 数据接口（2026-09-17）

Forward migration `20260917094631_crime_security_read_api.sql` 与远端登记版本一致。
`read_safety_inputs()` 无参数，SQL stable/security invoker/空 search_path；返回
`version/dataset_id/source_url/source_sha256/verified/latest_complete_year/rows`。
rows 是 `year/state/category/type/crimes`，只投影最近五个完整年度的原始警区叶记录州级合计。
排除 Malaysia、district=All、type=all，避免重复累加；无警区边界/人口查询。
已有 19,152 条官方镜像与 CSV 完整业务内容一致；CSV SHA-256
`800d488b426cd02f068179c626f7b4d2c5ba024f5b4b838fb0986fb7001c31be`，
规范化内容 MD5 `efb060e86024b8bd70eb32fbfd759e74`（仅完整性比对，不用于安全签名）。
完整来源年份 2016–2023；最新完整年度 2023。
RPC 每次核对已有镜像行数/完整内容 digest；未审计变动使 verified=false，不以最新插入行推断完整年度。
本任务没有重新导入、覆盖或删除政府数据；大学项目的一次性导入边界不变。
authenticated 有 RPC execute 与镜像 select，RLS 限已认证；anon/PUBLIC 无 RPC execute，
anon 无镜像读写，authenticated 无 insert/update/delete/truncate/references/trigger grant。

SQLite 在 Adapter 懒初始化：`cache_key/model_version/payload/source_year/fetched_at/expires_at`。
`all-reporting-states` 保存已验证输入；`location:<latitude>:<longitude>` 保存分析坐标及已解析的州/boundary version/同份输入。
TTL 严格三天，未来时间、过期、字段错配、损坏、模型版/来源错配均失效。
不保存账户、收藏 id、地点名称；退出保留；读取/离线 fallback 不延长原始取数时间。
Geo 暂时无网络可恢复同坐标公共结果；新坐标、明确 unresolved/ambiguous 或来源版本不可验证不选默认州。


## Socio-economic 本次增量数据边界（2026-09-17）

Migration `20260917151921_socio_economic_read_api.sql`：`read_socio_inputs(text,text)` 是 stable / security invoker，空 search_path；仅 authenticated 执行，函数内要求 auth.uid()。
返回 `version = 1`、`state`、可空 `district`，以及 `income_district` / `income_state`（date, income_median）、`gini_district` / `gini_state`（date, gini）、`percentiles`（date, percentile, variable, income）数组；空数组/原始 null 不补零。
读取五个既有镜像，客户端不自行猜测地区、不以 hies_state 替代 hh_income_state，不改变镜像业务字段。
州收入镜像已实际存在 308 行，最新 2024 年；原表 proposed 状态修正不代表相关 Feature 自动验收。

Budget 增量只 additive 地加入 `household_monthly_gross_income_rm numeric(12,2)`，nullable、非负，旧记录 null。
其归属与 owner-only RLS 沿用既有预案表；Socio 仅消费 Cost 模块 `CurrentBudgetReader` 的只读 current 结果。
Cost Adapter 读取 id/scenario_name/household_monthly_gross_income_rm/monthly_net_income/is_current/updated_at；姓名及账号字段不进入公共缓存。
完整预算 CRUD/切换页面及其联验仍由 B 负责，不因补齐此只读边界改为 Implemented。

SQLite `socio_public_cache`：cache_key、version=1、公开原始 payload、fetched_at、expires_at（3 天）；key 为 state/district/boundary version 或精确坐标。
只保存成功取得的公共输入与地区/边界事实，失败读取不延长期限；个人收入/预案/账号/收藏名不入库。
过期、未来采集时间及损坏 JSON 安全失效；退出允许保留。Geo 来源断网可用精确坐标快照，scopeUnavailable/ambiguity/noCoverage 不据旧快照伪造解析。
