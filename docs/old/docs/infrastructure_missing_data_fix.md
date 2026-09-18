# 基础设施评估：医疗密度 / 教育资源缺失成因分析与修复方案

## 1. 问题现象

在“基础设施评估”(ICI)界面：

- **部分地点缺失“医疗密度”与“教育资源”两项数据**（界面显示 `—`），通常同时缺失；
- **缺失数据的地点指数往往虚高到接近 100**，而**数据齐全的地点通常只有 80 上下**，
  导致跨地点比较时结论失真（数据更全、评估更严谨的地点反而“看起来更差”）。

## 2. 数据链路（现状）

```
界面地点(名称/坐标)
  └─ DistrictResolver.resolve()   → 行政区名(来自 hh_income_district 的 172 个县名)
       ├─ hh_access_amenities(供水/供电/卫生)   —— 县名精确相等查询
       ├─ hospital_beds(医疗床位)               —— type='all',取每县最新年份,min-max 归一
       ├─ teachers_district / enrolment_school_district(师生比) —— min-max 归一
       └─ transit_stops(2km 站点密度,需坐标)    —— 无坐标则该项无数据
```

各子项取不到数据时返回 `null`；旧版 ICI = **只对“非空子项”求均值**，
缺失子项既不进分子也不进分母，也没有任何数据完整性提示。

## 3. 为什么部分地点缺失这两项（实证结论）

我们用与本项目同源的数据（docs 记载的 ETL 均来自 Data.gov.my：
`hospital_beds`、`teachers_district`、`enrolment_school_district`、`hh_access_amenities`）
做了全量核对与按仓库逻辑的逐县模拟，结论是三个叠加原因：

### 3.1 上游表本身的覆盖缺口（真缺）

- **医院床位表按“医院所在县”统计**：无医院的县 / 部分联邦小县没有对应行
  （实测：Kuala Nerus、Kalabakan、Muallim、Bagan Datuk、Tangkak、Kuala Penyu、
  Membakut 及沙砂多个人口稀少的新设 DOSM 县 Gedong/Lingga/Pantu/Sebuyau/Siburan/
  Maradong/Kecil Lojing 等均无行）。
- **教育部师生表按 PPD/学区口径发布**：部分小县不单独成行，或与邻县合并成一条
  （实测合并写法：`Tatau/Sebauh`、`Telupid/Tongod`、`Kulim/Bandar Baharu`、
  `Jempol/Jelebu`、`Larut/Matang/Selama`），教师与学生表还彼此不对齐
  （2025 年实测：教师表有 `Bangsar Pudu/Sentul/Keramat/Jpwp Putrajaya` 等 PPD 名，
  学生表却是 `W.P. Kuala Lumpur/W.P. Putrajaya` 行政区名）。
- **年份口径**：教师/学生表的旧年份与新年份县名体系不同（2023 年起按新拆分县发布：
  `Petaling` → `Petaling Perdana`/`Petaling Utama`，`Kinta` → `Kinta Selatan`/`Kinta Utara`，
  `Hulu Langat` → `Ulu Langat` 等）。仓库代码未限制年份、仅按县名前缀匹配，
  一旦某县在某年改名/拆分，交叉匹配就可能落空。

### 3.2 县名写法差异导致的“假缺失”（命名不对齐）

各表对同一县的写法不统一，而仓库代码只做“前缀 / 包含”字符串匹配：

| 解析出的县名（hh_income_district） | 上游表写法 | 旧匹配结果 |
|---|---|---|
| `S.P. Selatan / S.P.Tengah / S.P.Utara` | `Seberang Perai Selatan/…` | 缺失 |
| `Ulu Langat` | `Hulu Langat`（或 `Hulu Langat (Bangi)`） | 缺失 |
| `Larut & Matang` / `Larut dan Matang` | `Larut & Matang (Taiping)` | 部分缺失 |
| `Kulai` | `Kulaijaya`（医院表） | 缺失 |
| `W.P. Kuala Lumpur` 等联邦直辖区 | 有的表写 `Kuala Lumpur`、有的加 PPD 名 | 部分缺失 |
| `Tatau` / `Sebauh` | `Tatau/Sebauh`（师生表并县） | 一半缺失 |

> 医院表历史原因还带括号别名（`Petaling (Subang Jaya)`、`Timur Laut (Georgetown)`），
> 旧代码靠前缀匹配恰好能覆盖，但换到上述其它差异就无能为力。

### 3.3 供水/供电项也受同样问题影响

`hh_access_amenities` 采用**县名精确相等**查询，实测有 14 个解析名在该表中不存在
（含上述缩写/用字差异），这些地点若坐标也不选，就会出现“只剩 transit 一项、均值 = 100”的极端情况。

### 3.4 对照模拟结论

按仓库现有逻辑对上游全量数据逐县模拟（n=172）：

- 医疗（床位）匹配失败：20 个县；教育（师生比）匹配失败：19 个县；**两项同时缺失：11 个县**
  （Gedong、Kalabakan、Lingga、Membakut、Pantu、S.P. 三县、Sebuyau、Selama、Siburan）。
- 现象示例（transit 取 100 演示）：

| 地点 | 水 | 电 | 医疗 | 教育 | 旧 ICI（仅非空求均值） |
|---|---|---|---|---|---|
| W.P. Kuala Lumpur（数据齐全） | 100 | 100 | 100 | 15 | **83.0** |
| Kinta / Johor Bahru（齐全） | 100 | 100 | ~69/62 | ~30/8 | **~74–80** |
| Kalabakan（缺医疗+教育） | 84 | 100 | — | — | **94.8** |
| Siburan / S.P. Selatan（几乎全缺） | — | — | — | — | **100.0**（仅剩 transit） |

“缺数据=均值只看剩余项”让分母变小、且留下的恰好都是高分项，
所以缺数据的地区可以轻松到 100——这正是不公平的根源。

## 4. 解决方案（已落地）

### 4.1 评分公平口径：固定基期 + 缺失按 0 计 + 完整性提示

新增 `lib/core/ici_score.dart`（纯函数，仓库与 Provider 共用同一公式）：

1. **固定基期**：ICI 永远按权重和（默认 5 项各 0.2）计算，
   不再因为某项缺失就缩小分母；
2. **源数据缺失 ≠ 满分**：缺失项分数按 **0** 计入、权重保留在分母
   （保守下限，宁可低估、不虚高，避免缺数据地区“躺赢”100）；
3. **坐标未选 ≠ 该地无交通**：`transit` 未评估时（未传坐标），该项权重与分数一并剔除，
   避免把“用户没选点”当成“该地没公共交通”误伤；
4. 全部子项都无数据 → ICI 返回 `null`（界面 `—`）。

效果（同表演示，transit=100）：

| 地点 | 旧 ICI | 新 ICI |
|---|---|---|
| W.P. Kuala Lumpur | 83.0 | 83.0（不变，全数据） |
| Kalabakan | 94.8 | **56.9**（缺 2 项按 0） |
| Siburan / S.P. Selatan | 100.0 | **20.0**（仅 1 项有数据） |

- 仓库 `infrastructure_repository.dart` 与 Provider 的滑块重算 `weightedIciScore`
  已统一改为该口径（含旧缓存兼容：`transit_applicable` 缺失时回退判断）。
- 界面 `infrastructure_view.dart`：数据不完整时——
  - 顶部徽章显示“**数据不完整**”（不再给“优秀/良好”误导性评级）；
  - 大数字下方追加说明行：*“缺少 医疗密度、教育资源 等 N 项数据，缺失项按 0 计入指数，仅供参考”*；
  - 缓存键升级 `infrastructure_v2 → infrastructure_v3`，避免旧缓存沿用旧公式。

### 4.2 县名跨源归一，消除“假缺失”

新增 `lib/core/district_matcher.dart`（纯函数）：
小写、去标点、去连接词（dan/and/the/of）、忽略 `W.P.` 前缀，然后按
“相等 / 行名前缀含查询名 / 查询名前缀含行名 / 组成县命中（≥5 字符）/ 已知别名”
宽松匹配。覆盖了 3.2 中全部实测差异（含 `S.P.*`→`Seberang Perai *`、`Ulu/Hulu`、
`Kulaijaya/Kulai`、`Petaling`→拆分县、`Tatau/Sebauh` 并县等）。

- `hospital_beds`、`teachers_district`/`enrolment_school_district` 的目标县匹配改用它；
- `hh_access_amenities` 在精确匹配失败时，降级为“全量拉取 + 宽松匹配选最新年份”，
  补齐 3.3 所列 14 个县的供水/供电数据。

> 设计上刻意**不做“行名是查询名前缀”的反向匹配**：例如 `Sibu` 是 `Siburan` 的前缀，
> 但两者是不同的县，反向规则会把无关县的床位/师生数误聚合给该县（已用单测锁定防回归）。

按上游全量数据复算（n=172）：医疗缺失 20 → **16**、教育缺失 19 → **14**、
双缺 11 → **7**；剩余未覆盖的基本是上游真没有行的县（沙砂偏远小县、无医院县等），
需靠 5.1 的数据刷新/补数解决，而不会再因命名写法规避。

配合 4.1，真正没有数据的县（如沙砂偏远小县）会明确显示“数据不完整”，而不再伪装成 100 分。

### 4.3 测试

`test/core/ici_score_test.dart`、`test/core/district_matcher_test.dart` 覆盖新公式与全部匹配规则。

### 4.3 指标口径更新（每千人口医疗 + 教育同年横截面）

**医疗 → 每千人口床位。** 新增县人口表 `district_population`（DOSM 年度县人口，
建表 + 种子 SQL：`scripts/seed_district_population.sql`，在 Supabase SQL Editor 执行一次）。
仓库层按“每千人口床位 = 床位数 ÷ 人口 × 1000”在全国同年横截面 min-max 归一；
每个县以其“床位最新年份”对齐人口（优先取 ≤ 该年份的最近人口，否则取该县最新人口）。
人口表缺失/目标县无人口时**自动回退**到旧的绝对床位数口径，不会劣化。

离线预演（对照旧“绝对床位 min-max”）：

| 县 | 床位 | 人口(2022) | 每千人口 | 旧分 | 新分 |
|---|---|---|---|---|---|
| W.P. Kuala Lumpur | 4874 | 1,961,200 | 2.49 | 100.0 | **45.6** |
| W.P. Putrajaya | 637 | 117,000 | 5.44 | 13.1 | **100.0** |
| Kota Kinabalu | 2175 | 500,800 | 4.34 | 44.6 | **79.8** |
| Petaling | 490 | 2,304,800 | 0.21 | 10.1 | **3.9** |
| Gombak | 3153 | 950,200 | 3.32 | 64.7 | **60.9** |
| Kinta | 3354 | 895,800 | 3.74 | 68.8 | **68.8** |

> 不再让“绝对床数最多的县”恒拿 100。注意上游医院数据按“医院所在统计区”归口、
> 人口按全县统计，归口口径不一致的地区（如 Petaling 只统计了部分站点床位但除以全县人口）
> 仍会偏低，属数据源本身的粒度问题，可通过后续按城市/县融合数据缓解。

**教育 → 同年横截面。** 归一池从“所有年份混合”改为“只取与目标县同一报告年的
全国各县师生比”，基准不再逐年漂移（目标县绝大多数落在 2025-06-30 报告年，
该年池约 140 个县）。

## 5. 进一步建议（超出本次改动，视产品目标取舍）

1. **数据层根治（推荐）**：重跑 Data.gov.my ETL 刷新 Supabase 各表（现在源数据已更新到
   2025-06-30 年份，且含新拆分县）；或在库内新增 `district_alias` 映射表/视图，
   让各功能页共用同一套“县名 → 各表键”的对照。
2. ~~医疗指标口径~~ **已完成**：床位绝对数 → 每千人口床位（人口表见 4.3；
   若后续拿到达 2022 年县域人口还可进一步做医院归口校正）。
3. ~~教育指标口径~~ **已完成同年横截面**；仍待办的是**阶段对称**：学生表含
   `post_secondary` 而教师表不含，师生比分母被系统性放大，
   建议两侧都限定 `primary + secondary`（需重新核对当年横截面分布后切换）。
4. **产品层**：如果希望“数据不完整”的地点不参与横向比较，可在对比/收藏功能里
   对 `missing` 非空的地点加过滤或降序置底。
