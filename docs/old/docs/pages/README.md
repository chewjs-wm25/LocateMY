# 页面功能状态总览

核对范围：`lib/modules/module_{a,b}/views/` 及同一 Module 内的 `view_models/`、
`repositories/`、`models/`。状态仅表示当前仓库实现，不表示后端部署环境一定已有完整数据。

## 页面导航关系

```text
AppShell
├─ 未登录 → 登录页 → 注册页
└─ 已登录
   ├─ 首页
   ├─ 地图页
   │  ├─ 生活开销
   │  ├─ 治安与犯罪 → 房产新增/详情/档案/对比/回收站
   │  ├─ 社会经济
   │  ├─ 基础设施
   │  ├─ 周边设施
   │  └─ 公共交通
   └─ 账户中心 → 房产档案 / 我的隐患报告
```

## 页面清单

| 页面 | 实现文件 | 状态摘要 | 页面文档 |
| --- | --- | --- | --- |
| 应用壳层 | `views/app_shell.dart` | 已完成认证门控、双 Tab、语言切换 | [查看](./app_shell.md) |
| 登录/注册 | `views/account/login_view.dart`、`register_view.dart` | 邮箱密码认证已完成；Magic Link/游客未完成 | [查看](./authentication.md) |
| 首页 | `views/home/home_screen.dart` | 宏观指标、指数、GDP 趋势与刷新已完成 | [查看](./home.md) |
| 地图 | `views/map/map_view.dart` | 选点、对比、收藏、搜索、隐患及分析入口已完成；投票持久化未完成 | [查看](./map.md) |
| 生活开销 | `views/cost_of_living/cost_of_living_view.dart` | CPI/物价对比、预案读取/新建/改名/删除已完成；金额编辑和商家下钻未完成 | [查看](./cost_of_living.md) |
| 治安与犯罪 | `views/crime_security/crime_security_view.dart` | 警区匹配、趋势、边界/隐患图层已完成 | [查看](./crime_security.md) |
| 社会经济 | `views/socio_economic/socio_economic_view.dart` | 收入、排名、基尼、拟合分布和收入百分位已完成 | [查看](./socio_economic.md) |
| 基础设施 | `views/infrastructure/infrastructure_view.dart` | ICI、分项分数和三项权重调节已完成 | [查看](./infrastructure.md) |
| 周边设施 | `views/infrastructure/nearby_facilities_view.dart` | OSM 2km POI 分类与重试已完成 | [查看](./nearby_facilities.md) |
| 公共交通 | `views/transport/transportation_view.dart` | 1.5km 站点、评分、地图定位已完成；路线未完成 | [查看](./transportation.md) |
| 账户中心 | `views/account/account_view.dart` | 用户信息/入口/退出已完成；历史与统计为占位 | [查看](./account.md) |
| 我的隐患报告 | `views/account/reported_hazards_screen.dart` | 用户报告读取、删除、回地图定位已完成 | [查看](./reported_hazards.md) |
| 房产新增/编辑 | `views/property/add_property_screen.dart` | 表单、检查表、位置与风险补全已完成；照片与持久化不完整 | [查看](./property_form.md) |
| 房产档案/详情 | `views/property/property_archive_screen.dart`、`property_detail_screen.dart` | 查看、编辑、软删除、恢复入口已完成（仅内存） | [查看](./property_archive.md) |
| 房产对比/回收站 | `views/property/property_comparison_screen.dart`、`recycle_bin_screen.dart` | 多选对比、恢复和清空已完成（仅内存） | [查看](./property_comparison_and_recycle_bin.md) |
| 气候与水灾独立页 | 无对应 `lib/modules/*/views/` 文件 | 未完成；仅有旧设计文档及分散风险字段 | [查看](./climate_flood.md) |
