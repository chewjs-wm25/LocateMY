# 交通补充数据下载目录

将下载的原始 GTFS ZIP 文件保存到本目录，暂时不要解压或修改里面的文件。

## 下载地址及保存名称

| 资料 | 官方 ZIP 下载地址 | 建议保存文件名 |
| --- | --- | --- |
| BAS.MY 怡保 | [下载怡保 GTFS](https://api.data.gov.my/gtfs-static/mybas-ipoh) | `gtfs_static_mybas_ipoh.zip` |
| BAS.MY 芙蓉 A | [下载芙蓉 A GTFS](https://api.data.gov.my/gtfs-static/mybas-seremban-a) | `gtfs_static_mybas_seremban_a.zip` |
| BAS.MY 芙蓉 B | [下载芙蓉 B GTFS](https://api.data.gov.my/gtfs-static/mybas-seremban-b) | `gtfs_static_mybas_seremban_b.zip` |

来源：[马来西亚官方 GTFS Static API 文档](https://developer.data.gov.my/realtime-api/gtfs-static)。芙蓉有两个运营商，需下载 A、B 两份。2026-09-18 核对：以上三个下载地址均返回 HTTP 200 和 application/zip。

## 为什么需要这些资料

上一轮以吉隆坡中心坐标和 2026-09-18 分析日期复现时，数据库中的这三个 feed 被判为超出服务日期范围；并不是数据库完全没有其站点文件。它们属于全国来源完整性检查，吉隆坡本身的主要交通来源仍可读取。

下载地址返回官方当前版本，不能保证其服务日期已经更新，也不能保证覆盖所需分析日期。下载后需检查 `calendar.txt` 的 start_date / end_date 及 `calendar_dates.txt` 的日期例外；如果官方仍发布同一旧版本，重新下载也不能补齐日期范围，不应手动延长日期冒充有效服务。

## 另一个缺项：评分参照网格

2026-09-18 的密度、路线百分位参照网格不是官方 GTFS ZIP 的一部分，没有官方下载地址。它需要项目根据同一快照及分析日期重新生成，现有工具是 `tool/prepare_transit_reference_grid.py`；不要用其他日期的网格替代。

保存 ZIP 后仍需校验、准备标准化数据及对应日期的参照网格，再执行受控导入；仅将文件放进此目录不会自动更新应用或数据库。当前应用已支持部分交通分，在资料未补齐时也可显示可计算的读数和缺项说明。

本目录 ZIP 文件仅在本地保存，已通过 .gitignore 排除提交。
