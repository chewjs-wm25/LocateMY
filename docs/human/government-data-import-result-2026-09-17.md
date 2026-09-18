# 政府数据导入结果（2026-09-17）

远端项目：ntlhjfljkjeefzzqutbc。已完成用户授权的导入；保持 Supabase Free，PriceCatcher 仅保留固定 cost-basket-v1 商品价格。未改变篮子定义、业务字段或缺失值语义。

## 远端结果

| 镜像 | 最终行数 | 数据范围 |
| --- | ---: | --- |
| hh_inequality_state | 289 | 1974–2024；最新年 16 州 |
| hies_state_percentile | 19,200 | 2019/2022/2024；16 州完整百分位；保留 96 个官方隐私空值 |
| population_district | 383,040 | 2020–2025；每年 160 行政区完整维度 |
| lookup_item | 797 | 完整官方维表；保留官方 -1 占位 |
| lookup_premise | 3,916 | 完整有效主键行；隔离一条空主键原始行，保留 -1 占位 |
| pricecatcher | 460,019 | 2025-10 至 2026-09；最新实际日期 2026-09-15；仅固定篮子 11 个 item_code |

所需业务镜像表已经存在且结构正确，本次补齐数据。迁移 20260917111636 新增独立 government_data_import_files 表，登记 5 个统计/维表文件、12 个月价格文件与 16 个 feed，共 33 个来源；其来源 SHA-256、筛选规则、有效导入行数及空主键拒绝计数可追溯。迁移已应用并登记本地和远端。

修正两张社会经济表此前不必要的客户端 DML grant：authenticated 仅 SELECT，anon 无访问。新增审计表启用 RLS，无客户端 policy/grant，仅 service_role 可 SELECT/INSERT/UPDATE。业务镜像未增加来源、导入时间等辅助字段。

根据用户明确选择，PriceCatcher 只导入代码：

`1,16,118,224,272,904,918,1541,1589,1605,1645`

原有 151,400 行在筛选前完整备份到 `build/government-import-2026-09-17/pricecatcher-before-filter.jsonl`，备份 SHA-256 为 `08dd0d2e99475cd993d296931a62c1c862636e5ea9f2cc3204a96a47bec0f002`。随后移除 148,091 条非篮子旧价格，再按官方主键 upsert 12 个月筛选价格；最终非篮子行数为 0，原始下载文件未修改。

原始完整价格文件包含 20,192,022 行；除篮子外的 19,732,003 行没有导入。全部已选价格均可关联商品及商户维表。

## 交通

新批次：`manual-2026-09-17-complete`，分析日期 2026-09-17；16 个 feed 全部 usable。

| 对象 | 新批次行数 |
| --- | ---: |
| gtfs_feed_snapshots | 16 |
| gtfs_stops | 17,611 |
| gtfs_routes | 452 |
| gtfs_service_dates | 42,707 |
| gtfs_stop_service_links | 44,823 |
| transit_reference_grid | 10,271 |

原 15 个成功 feed 保留已有 ZIP 内容与采集时间；关丹使用用户指定的 [Mobility Database 归档](https://mobilitydatabase.org/feeds/gtfs/tld-6768)，保留 2026-07-23 归档来源，SHA-256 为 `5a7d1010a22e61f2720fef3abc634c6c452703b6e5f59788080a71a0ad195a86`。source_url 采用既有 RPC 所要求的官方 producer URL；实际 archive download URL 与归档说明在独立导入审计中记录，未表述为当天从官方端点取得。

参照网格按既有 UTM WGS84 1 km 固定原点与 1.5 km 站点覆盖方法重新计算。本地标准化记录与输入文件核验通过；全网格已上传并逐行核对，随后显式推广新批次。旧 official-2026-09-17 的部分批次保留。部分 BAS.MY feed 的服务日期仍只有 2026-09-17，不能保证其他分析日期完整可评分。

## 验证与容量

- 5 张统计/维表与本地已归一化来源的精确行数和内容摘要一致。
- 12 个月 PriceCatcher 的精确行数及双内容摘要分别全部一致；价格摘要采用与镜像数值类型一致的两位小数表示。
- 使用 test_credentials.local.md 中的真实账号验证六张政府镜像的登录读取成功；匿名读取和客户端写入被拒绝；审计表对客户端读取被拒绝。证据未包含账号、密码或 token。
- Flutter 交通真实测试通过：最新完整批次返回有效交通结果和 0–100 分，全部 16 feed 可用；2040 年超出服务日范围正确不可用；匿名 RPC 与客户端写入被拒绝。
- `flutter analyze test/live/public_transportation_live_test.dart` 无问题；交通目录的 29 项测试通过；修改的 Dart 测试已 format；3 个 Python 导入/网格工具编译检查通过；git diff --check 通过。
- 数据库实测约 **357 MiB**（373,976,211 bytes，查询时点），仍低于 Free 500 MB 限额；未升级套餐。[官方容量规则](https://supabase.com/docs/guides/platform/database-size)

已运行安全 advisor。新增审计表 RLS 无 policy 是故意禁止客户端访问；既有行政区/边界审计表采用同样策略。[对应说明](https://supabase.com/docs/guides/database/database-linter?lint=0008_rls_enabled_no_policy)。现有 PostGIS 系统表/扩展和 SECURITY DEFINER 的通知属于之前的数据库对象，并不因本次导入新增；现有 pre-request guard 保留，本次未迁移 PostGIS 扩展。对应 [RLS 说明](https://supabase.com/docs/guides/database/database-linter?lint=0013_rls_disabled_in_public)、[扩展说明](https://supabase.com/docs/guides/database/database-linter?lint=0014_extension_in_public)、[函数权限说明](https://supabase.com/docs/guides/database/database-linter?lint=0028_anon_security_definer_function_executable)。

## 仍然缺失的官方观测

固定篮子的面包（272）、洗洁精（1541）、咖啡（1645）在这 12 个月均无价格；鸡蛋（118）全国仅 25 条。数据库没有补零、虚构观测或替换商品。因此导入任务已完成，但不能声称完整生活成本指数及预算压力的数据门槛已满足。后续需遵循现有部分资料状态；如果要改变篮子，须产品确认新版本。

## 维护与证据

手动导入工具：`tool/import_government_datasets.py`。仅读取本地下载文件，以 service_role 受控执行，按主键 upsert，有限并发并支持同来源 SHA-256 的分块恢复；不由 Flutter 或调度器调用。导入 checkpoint 和源文件摘要保存在被 Git 忽略的 build 目录。

交通和网格工具增加 --root，使归档导入证据不覆盖旧批次目录。关键证据位于 `build/government-import-2026-09-17/`：
- 各文件 -import-audit.json、remote-content-verification.json。
- pricecatcher-before-filter.jsonl 与其备份审计。
- live-permissions.json、transit-live-test.log。
- transit/official-download-audit.json、normalized-snapshot.json、reference-grid-audit.json、reference-grid.json。

本次是数据维护与相关验证，不是新 Feature/Wave 交付；未改变应用生产 Dart 行为，未进行 APK/设备界面验收，也未将尚未实现的 Cost/Socio/Infrastructure Feature 标记为完成。

