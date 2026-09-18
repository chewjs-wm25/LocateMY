---
kb_id: locatemy-capability-catalog
kind: capability-index
canonical: true
---

# 功能能力目录

`ID` 是后续需求、任务和测试引用的稳定标识。

本目录记录的是 UI 原型展示出的能力意图及其研究状态，不代表正式产品已经开发或上线。`working` 表示原型中有可见/可操作的演示行为，不能解读为生产功能已实现；真实数据、持久化、认证和同步仍待正式开发。

截至 2026-09-13，当前 `Rework` 工作树的 `lib/` 不包含本目录所引用的原型页面实现；经 Git 核实，历史原型代码位于 `Prototype` 分支（远端对应 `origin/Prototype`）。目录中的状态和事实是产品意图及该历史原型记录，不表示这些页面在 `Rework` 当前分支仍可运行。

| ID | 能力 | 当前状态 | 当前事实 | 分类 |
| --- | --- | --- | --- | --- |
| NAV-01 | 认证门控 | prototype | 原型包含登录/注册页与主应用，但未展示按认证状态阻挡主应用的门控流程 | `required` |
| NAV-02 | 首页/地图双 Tab | working | 使用两个一级页面并保留同进程页面状态 | `required` |
| NAV-03 | 中英文切换 | placeholder | 原型显示语言入口，但没有可验证的切换行为 | `required` |
| AUTH-01 | 邮箱密码登录 | prototype | 原型展示邮箱/密码字段和登录入口；真实校验、认证和反馈未开发 | `required` |
| AUTH-02 | 账户注册 | prototype | 原型展示用户名、邮箱、密码和确认密码字段；真实校验和注册未开发 | `required` |
| AUTH-03 | 真实验证状态 | excluded | 2026-09-17 取消邮箱确认及验证界面 | `excluded` |
| HOME-01 | 搬迁建议与指数 | prototype | 原型展示建议、指数及宏观解释；数值是示例 | `required` |
| HOME-02 | 宏观指标仪表盘 | prototype | 原型展示失业/就业、收入、成本压力和经济动能卡片；目标数据来自政府开放数据 | `required` |
| HOME-03 | 首页刷新 | placeholder | 当前原型没有刷新按钮或下拉刷新控件 | `required` |
| MAP-01 | 地图浏览与点选 | prototype | 原型展示非真实比例地图插图和预设地点选择，不是可用地图 | `required` |
| MAP-02 | 地点自动补全 | prototype | 原型搜索入口打开预设地点选择，不是自动补全 | `required` |
| MAP-03 | 单点显示模式 | prototype | 原型可切换两个预设地点并展示单点摘要 | `required` |
| MAP-04 | 两地对比选择 | prototype | 原型可选择/清除 A/B、交换并阻止相同地点比较 | `required` |
| MAP-05 | 收藏地点 | prototype | 原型展示收藏按钮和固定地点列表；正式收藏记录、删除和同步未开发 | `required` |
| MAP-06 | 六类分析入口 | prototype | 单点可进入六类分析；两地可进入 A/B 六类比较总览；数值为原型 fixture | `required` |
| MAP-07 | 个人化地点适配度 | excluded | 2026-09-17 取消总分，保留各项分析与预算压力 | `excluded` |
| COST-01 | 生活成本分析与比较 | partial | 有单点生活成本报告和 A/B 生活成本比较；数据和部分结果为原型 fixture | `required` |
| COST-02 | 临时月预算换算 | excluded | 2026-09-18 用户明确删除 CPI 等效预算换算器 | `excluded` |
| COST-03 | 预算预案 CRUD | partial | 远端增查改删名称及三类金额，但页面编辑能力不完整 | `required` |
| COST-04 | 查看商家 | placeholder | 按钮无回调 | `excluded` |
| COST-05 | 预算 JSON 导出与读取 | excluded | 2026-09-18 用户明确移除本机导出文件与 JSON 导出／读取功能 | `excluded` |
| SAFE-01 | 州级安全指数与趋势 | working | 州级整体指数、犯罪分类、按类趋势 | `required` |
| SAFE-02 | 安全地图 | excluded | 警区边界资料不可获取，警区地图已从范围移除 | `excluded` |
| SAFE-03 | 犯罪类别筛选 | working | 仅改变州级趋势线，不改变总分 | `required` |
| SOCIO-01 | 收入结构 | working | B40/M40/T20、收入、排名、基尼与分布 | `required` |
| SOCIO-02 | 用户收入位置 | partial | 当前页面没有真实用户收入位置数据服务；社会经济页面保留示例/缺失状态 | `required` |
| SOCIO-03 | 两地社会经济对比 | partial | A/B 比较总览和详情可展示示例收入、基尼读数；尚未接入真实数据 | `required` |
| INFRA-01 | 基础设施综合与分项 | working | ICI、水、电、医疗、教育与缺失提示 | `required` |
| INFRA-02 | 个性化需求权重 | partial | 当前原型有医疗、教育和交通三个 ICI 滑块，即时重算且不持久 | `required` |
| FAC-01 | 2km 周边设施分类 | working | 当前原型为六类、总数、最近距离、每类三项；重开发采用五类 OSM 查询 | `required` |
| FAC-02 | 设施详情/展开 | placeholder | 行箭头和“其他 N 项”不可操作 | `excluded` |
| TRANSIT-01 | 1.5km 站点与评分 | working | 最多 30 站、列表、评分和地图 | `required` |
| TRANSIT-02 | 站点选中 | working | 高亮站点并展示步行提示，不移动地图 | `required` |
| TRANSIT-03 | 站点分布图 | partial | 当前原型用站点 Marker 与范围圆展示，名称曾误写为热力图 | `required` |
| PROP-01 | 房产新增/编辑 | prototype | 表单完整，但只保存在内存 | `required` |
| PROP-02 | 房产实勘照片 | prototype | 添加 mock 字符串，显示随机网络图 | `required` |
| PROP-03 | 房产档案/详情 | prototype | 3 条启动演示数据，可查看和编辑；当前没有删除/回收站 | `required` |
| PROP-04 | 房产多选对比 | prototype | 最少 2 项，当前原型最多 3 项，结果不保存 | `required` |
| PROP-05 | 房产回收站 | placeholder | 当前原型没有回收站、恢复或清空控件 | `required` |
| HAZ-01 | 地图隐患上报 | prototype | 原型展示五类隐患、标题/描述字段和提交入口 | `required` |
| HAZ-02 | 隐患图层与详情 | placeholder | 当前原型没有地图隐患图层或详情页 | `required` |
| HAZ-03 | 隐患投票 | placeholder | 当前原型没有投票控件 | `required` |
| HAZ-04 | 我的隐患报告 | prototype | 原型展示两条固定示例报告；真实刷新、定位和删除未开发 | `required` |
| ACCOUNT-01 | 用户信息 | prototype | 原型展示固定姓名、邮箱和验证徽章 | `required` |
| ACCOUNT-02 | 房产/隐患入口 | prototype | 原型可进入对应页面 | `required` |
| ACCOUNT-03 | 搬迁评估历史 | placeholder | 空回调，无页面和数据 | `excluded` |
| ACCOUNT-04 | 默认地点 | placeholder | 仅改变本页开关外观 | `excluded` |
| ACCOUNT-05 | 保存的对比 | placeholder | 两条固定示例，点击无效 | `excluded` |
| ACCOUNT-06 | 评论/点赞统计 | placeholder | 固定 3 与 12，无详情功能 | `excluded` |
| ACCOUNT-07 | 退出登录 | prototype | 原型有退出入口并跳转登录页；真实会话清除和隔离未开发 | `required` |
| ACCOUNT-08 | 账户评估偏好 | excluded | 2026-09-17 随适配度总分删除设置、保存逻辑与数据依赖 | `excluded` |
| ACCOUNT-09 | 当前评估预案 | partial | 原型展示预案摘要行并可进入生活成本页；未连接账户服务 | `required` |
| CLIMATE-01 | 独立气候/水灾页 | excluded | 当前无页面、入口或隐藏路由 | `excluded` |

## 产品范围基线（2026-09-13）

2026-09-17 已确认修订：`AUTH-03`、`MAP-07`、`ACCOUNT-08` 改为 `excluded`。2026-09-18 用户明确将 `COST-05` 预算 JSON 导出与读取改为 `excluded`，不再保留本机导出文件。在线账号记录、退出、照片和房产风险的成果按下表更新；历史原型事实不等同于当前代码状态。

分类含义：`required` 在交付范围内实现并验收，大学提交承诺覆盖的能力全部属于此类；`excluded` 本次不做，重新引入需要新的明确需求；`deferred` 推迟但不阻塞 required 流程；`superseded` 已被取代。当前 `deferred` 与 `superseded` 为空，已废弃的数据表属于 schema 迁移问题，不构成 Capability。

每个已知 Capability 恰好只有一个分类；分类变化必须由项目负责人批准并在本目录更新。下表是每个 `required` 能力的权威产品事实源与可观测成果；`excluded` 项的依据见
[redevelopment_scope.md](redevelopment_scope.md) 的「已决定排除」。

| ID | 权威产品事实源 | 可观测用户成果 |
| --- | --- | --- |
| NAV-01 | [global_navigation](features/global_navigation.md) | 未登录用户无法进入主应用；登录成功后进入主应用 |
| NAV-02 | [global_navigation](features/global_navigation.md) | 用户可在首页与地图两个一级 Tab 间切换并返回，同进程内保留各自页面状态 |
| NAV-03 | [global_navigation](features/global_navigation.md)、[ui_design_spec](ui_design_spec.md) | 用户可切换中英文，同一功能集合的页面、状态与错误信息均以所选语言显示，偏好跨重启保留 |
| AUTH-01 | [authentication](features/authentication.md) | 已注册用户可用邮箱和密码登录并建立会话；失败时看到可恢复反馈 |
| AUTH-02 | [authentication](features/authentication.md) | 新用户可用邮箱、密码和确认密码注册，成功后进入应用，无邮箱确认流程 |
| AUTH-03 | [authentication](features/authentication.md) | 已排除：取消邮箱确认要求与验证界面 |
| HOME-01 | [home](features/home.md)、[home_index_scoring](home_index_scoring.md) | 首页显示 0–100 全国搬家时机分、状态和最多三条原因 |
| HOME-02 | [home_index_scoring](home_index_scoring.md) | 首页显示成本压力、就业、经济动能与家庭收入中位数卡及单位 |
| HOME-03 | [home](features/home.md) | 用户可通过按钮或下拉刷新宏观指标；成功刷新后 60 秒内提示剩余冷却秒数 |
| MAP-01 | [map_location](features/map_location.md)、[submission_commitments](submission_commitments.md) | 用户可在可缩放、可拖动的 OpenStreetMap 上浏览和点选，看到图钉与图层；范围外坐标被拒绝 |
| MAP-02 | [map_location](features/map_location.md)、[submission_commitments](submission_commitments.md) | 用户输入地点名时获得限于马来西亚的自动补全结果并选定坐标 |
| MAP-03 | [map_location](features/map_location.md) | 单点模式下地图显示一个主色 Marker 与该地点的可折叠摘要 |
| MAP-04 | [map_location](features/map_location.md) | 两地模式下用户可选择、清除并交换地点 A/B，相同地点被阻止，A/B 只表示呈现顺序 |
| MAP-05 | [map_location](features/map_location.md)、[submission_commitments](submission_commitments.md) | 用户可按账户保存、查看和删除收藏地点，登录同一账户可直接在线读取云端记录，无离线创建与同步队列 |
| MAP-06 | [map_location](features/map_location.md) | 用户可从合法单点进入六类分析，或从有效 A/B 进入六类比较总览；缺少合法地点时不可进入 |
| MAP-07 | [map_location](features/map_location.md) | 已排除：不再显示个人化地点适配度总分 |
| COST-01 | [cost_of_living](features/cost_of_living.md)、[submission_commitments](submission_commitments.md) | 单点报告显示本地价格、篮子估算月支出、生活成本指数与资料覆盖；比较页以相同口径并列 A/B |
| COST-02 | [submission_commitments](submission_commitments.md) | 已排除：不再提供临时 CPI 等效预算换算器 |
| COST-03 | [cost_of_living](features/cost_of_living.md)、[submission_commitments](submission_commitments.md) | 用户可按账户新增、重命名、选择、编辑金额和删除预算预案；切换后依赖读数立即重算 |
| COST-05 | [cost_of_living](features/cost_of_living.md) | 已排除：不再导出、读取或保留预算 JSON 本机文件 |
| SAFE-01 | [crime_security](features/crime_security.md) | 单点页显示州级安全指数 0–100、最新完整年度案件数和最近五年趋势 |
| SAFE-03 | [crime_security](features/crime_security.md) | 切换犯罪类别只改变州级趋势图，并在控件下说明作用域 |
| SOCIO-01 | [socio_economic](features/socio_economic.md) | 单点页显示行政区（或标注州级回退）收入中位数、B40/M40/T20 和基尼系数及各自统计年份 |
| SOCIO-02 | [socio_economic](features/socio_economic.md) | 用户输入家庭月收入后看到州级参考百分位位置，或明确的低于 P1、高于 P100、暂不可用状态 |
| SOCIO-03 | [socio_economic](features/socio_economic.md) | 地点比较以 A/B 并列收入和基尼等相同口径读数，不可比时说明原因 |
| INFRA-01 | [infrastructure](features/infrastructure.md)、[infrastructure_index_scoring](infrastructure_index_scoring.md) | 单点页显示 ICI 与供水、供电、医疗、教育、公共交通五个分项，缺失项显示 `—` 并列出缺失资料 |
| INFRA-02 | [infrastructure](features/infrastructure.md) | 用户调整医疗、教育、交通 `1–10` 权重后 ICI 即时重算，权重按账户保存并在下次打开时恢复 |
| FAC-01 | [nearby_facilities](features/nearby_facilities.md)、[nearby_facilities_scoring](nearby_facilities_scoring.md) | 用户看到 2 公里内五类设施的覆盖类别数、各类数量与最近三项，以及查询、缓存和未知状态 |
| TRANSIT-01 | [transportation](features/transportation.md) | 用户看到 1.5 公里内站点数、最近距离、有效路线数与交通连通性分 |
| TRANSIT-02 | [transportation](features/transportation.md) | 选中站点时列表与分布图关联高亮并显示距离和步行提示，不改变全局选点 |
| TRANSIT-03 | [transportation](features/transportation.md) | 站点分布图显示分析中心、1.5 公里范围圆和站点 Marker |
| PROP-01 | [property_inspection](features/property_inspection.md)、[submission_commitments](submission_commitments.md) | 用户可新增和编辑房产实勘，记录跨重启保留 |
| PROP-02 | [property_inspection](features/property_inspection.md)、[submission_commitments](submission_commitments.md) | 用户可从相机或相册添加最多 20 张压缩后的私有照片，编辑说明与封面，并看到在线上传成功或失败反馈 |
| PROP-03 | [property_inspection](features/property_inspection.md)、[submission_commitments](submission_commitments.md) | 用户可打开档案与详情，看到四项评分、综合评分、照片和带采集时间的风险快照；风险仅在新增或坐标变化时重算，无手动刷新 |
| PROP-04 | [property_inspection](features/property_inspection.md)、[submission_commitments](submission_commitments.md) | 用户可并排对比 2–3 份房产记录 |
| PROP-05 | [property_inspection](features/property_inspection.md)、[submission_commitments](submission_commitments.md) | 删除的实勘进入可见回收站，可恢复或确认后永久清空（含照片文件） |
| HAZ-01 | [hazard_reporting](features/hazard_reporting.md)、[submission_commitments](submission_commitments.md) | 用户可在地图上以必填类型和标题创建隐患报告，并看到加载、成功或失败反馈 |
| HAZ-02 | [hazard_reporting](features/hazard_reporting.md)、[submission_commitments](submission_commitments.md) | 所有登录用户可在地图图层查看公共隐患并打开详情 |
| HAZ-03 | [hazard_reporting](features/hazard_reporting.md)、[submission_commitments](submission_commitments.md) | 每个登录账户可对同一报告赞成、反对或撤回，计数由投票记录计算 |
| HAZ-04 | [hazard_reporting](features/hazard_reporting.md)、[submission_commitments](submission_commitments.md) | 用户可查看本人报告列表、定位到地图并删除自己的报告 |
| ACCOUNT-01 | [account](features/account.md)、[authentication](features/authentication.md) | 账户页显示真实邮箱，不展示验证徽章 |
| ACCOUNT-02 | [account](features/account.md) | 用户可从账户进入房产实勘档案和我的隐患报告 |
| ACCOUNT-07 | [account](features/account.md)、[authentication](features/authentication.md) | 用户退出当前设备后回到登录页，不等待跨模块清理证明，不删除预算导出文件，其他设备会话不受影响 |
| ACCOUNT-08 | [account](features/account.md) | 已排除：删除五项评估偏好设置、保存逻辑与数据依赖 |
| ACCOUNT-09 | [account](features/account.md)、[domain_objects](domain_objects.md) | 用户可选择并保存一份当前评估预案，切换后预算压力等依赖预案的读数立即重算 |

本基线由项目负责人于 2026-09-13 逐项确认：`COST-04`、`FAC-02`、`ACCOUNT-03`–`ACCOUNT-06` 定为 `excluded`；语言偏好存本机键值存储且不绑定账号；ICI 权重按账户保存、默认 5、只影响基础设施单点 ICI；新增 `MAP-07`、`ACCOUNT-08`、`ACCOUNT-09`。`HAZ-03`、`PROP-05` 与 [ui_design_spec](ui_design_spec.md) 的冲突已按[提交承诺](submission_commitments.md)修正。2026-09-14，项目负责人因警区多边形边界资料不可获取，将 `SAFE-02` 改为 `excluded`，并将 `SAFE-01`／`SAFE-03` 固定为州级口径。2026-09-18 用户明确将 `COST-02` 列为 `excluded`。Issue #1 追踪。
