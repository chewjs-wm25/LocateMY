# Geographic Context：边界资料决策简报（2026-09-14）

> 状态：行政区资料决定已记录于[`RISK-GEO-02`](../design/system/risks-and-decisions.md#risk-geo-02-资料决定与未关闭证据)；这是一份研究材料，不是 `RISK-GEO-02` 的关闭证据，也不证明已导入或可读。

## 已核实的候选

### 行政区：OpenDOSM 的版本固定 GeoJSON（可立即作项目资料快照）

- **资料对象与权威性**：马来西亚国家统计局（DOSM）的官方 GitHub 组织发布 `data-open` 仓库；其 `administrative_2_district.geojson` 是行政区几何。OpenDOSM 将自己说明为马来西亚国家统计机构的开放数据门户。[DOSM GitHub 组织](https://github.com/dosm-malaysia)；[OpenDOSM](https://open.dosm.gov.my/)；[固定版本文件](https://github.com/dosm-malaysia/data-open/blob/21a78e98efd4cd9b022a27a1bf67d167076b7591/datasets/geodata/administrative_2_district.geojson)
- **许可/使用条件**：仓库许可允许复制、发布、分发、改编和商业/非商业利用；同时排除个人资料、第三方权利、专利、商标和设计权，不得暗示官方地位或背书，资料按现状提供。[DOSM `LICENSE.md`](https://github.com/dosm-malaysia/data-open/blob/21a78e98efd4cd9b022a27a1bf67d167076b7591/LICENSE.md)
- **可冻结的版本标识**：Git commit `21a78e98efd4cd9b022a27a1bf67d167076b7591`，以及该 committed blob 的 SHA-256 `3edb1022b2de371bba6b7afb9802b6fc6d747c86dbcc40abf2374a9134f3c561`；前者在 [raw URL](https://raw.githubusercontent.com/dosm-malaysia/data-open/21a78e98efd4cd9b022a27a1bf67d167076b7591/datasets/geodata/administrative_2_district.geojson) 锁定具体文件内容，二者可共同作为行政区 frozen import version。此资料的仓库历史没有提供测绘/法定边界参考版本，因此它是可复现的项目运行几何，不应表述为法定测量边界。

### 行政区：JUPEM MyGeoServe 的 `DA0080`（法定/测绘权威升级路径）

- **资料对象与权威性**：JUPEM 的 MyGeoServe 服务目录列出 `DA0070 District/Jajahan Boundary` 和 `DA0080 District/Jajahan Coverage Administrative`；国家基础地理空间数据清单（2026）也把 `DA0080` 定义为行政 District/Jajahan coverage。[MyGeoServe 目录](https://sites.google.com/jupem.gov.my/jupemgeospatialwebservices/home)；[2026 基础数据清单](https://www.mygeoportal.gov.my/sites/default/files/Dokumen_MyGeoportal/Senarai_Data_Fundamental_2026.pdf)
- **许可/取得约束**：公开清单未授予开放资料许可；其备注明确将资料发布政策交由资料提供机构决定。JUPEM FAQ 表示数码测量及制图资料须经 eBiz 取得一年期的 Digital Survey and Mapping Data Copyright Licence（收费）。[发布政策](https://www.mygeoportal.gov.my/sites/default/files/Dokumen_MyGeoportal/Senarai_Data_Fundamental_2026.pdf)；[JUPEM FAQ](https://www.jupem.gov.my/portalJupem/faq)
- **可冻结的版本标识**：公开证据没有该边界层的不可变发布版、校验和或可固定下载 URI；`DA0080` 和目录年份不能充当 frozen import version。采用前必须从交付方取得产品/图层名称、release 或 extraction 日期、许可/订单编号与交付文件 SHA-256。

### 警区：未发现可选择的公开权威边界资料

- **PDRM 的公开证据范围**：皇家马来西亚警察（PDRM）公开目录允许按州、district 和地点筛选其 District HQ、警局和警亭，并显示地图/地点清单；它证明 PDRM 维护可查询的地点目录，却没有发布「police district polygon」图层、下载格式、许可或版本标识。[PDRM 官方地点目录](https://rmp2u.rmp.gov.my/hubungi-kami?lang=en)
- **结论**：截至本研究，找不到一个同时具备 PDRM/其他官方发布者、警区多边形、明确许可/使用条件、以及可用于冻结导入的不可变版本标识的公开候选。因此没有证据支持以行政区资料、警局点位或第三方 GeoJSON 替代警区边界。

## 非候选说明

- MyGeoportal 的 UPI 公开说明只提供土地行政边界的代码和名称；空间格式仍要正式申请，故它不能替代 `DA0080` 多边形资料。[UPI FAQ](https://www.mygeoportal.gov.my/en/faq-0)
- 数据门户中的统计 `district` 字段和 PDRM 的 `crime_district` 统计可用于名称/统计关联，但不是坐标到区域的边界几何；它们不能证明空间匹配、离岛、重叠或边界点语义。

## 已记录决定与仍需交付

项目负责人已采用 **DOSM `administrative_2_district.geojson` 的 commit
`21a78e98efd4cd9b022a27a1bf67d167076b7591`** 作为行政区运行资料；实际导入审计仍须记录本简报所列
SHA-256。2026-09-14，项目负责人确认警区多边形资料不可能在本项目中获取，故警区解析和 `SAFE-02`
已从范围移除；Crime 改为使用行政资料解析的州来聚合 `crime_district.state`。本简报的警区调查结论
保留为该范围变更的证据，决定与剩余行政边界 Gate 的唯一权威是上述 `RISK-GEO-02` 记录。

## 证据边界

本简报只报告公开一手页面截至 2026-09-14 所能核实的内容。公开资料没有证明任一候选已经获 LocateMY 使用许可、已经下载，或能够通过 `GEO-002` 读取；这些状态均保持未知。
