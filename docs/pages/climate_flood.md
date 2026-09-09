# 气候与水灾独立页

需求来源：`docs/view/climate_flood_view.md`、对应旧 model/viewmodel/repository 文档。

## 当前结论

**未完成。** 当前 `lib/modules/*/views/` 中没有气候与水灾独立 Screen，也没有
MetMalaysia/JPS Repository、天气 Provider 或对应实体实现。

## 已在其他页面分散实现的相关能力

- 地图可展示用户上报的 flood 类型众包隐患。
- 房产检查包含水灾历史开关和排水、防水、湿度、照明检查项。
- 首页模型含搬迁建议，但没有实时天气/季风数据源。

## 旧文档中仍未完成的功能

- 7 天天气预报、MetMalaysia 数据接入。
- JPS InfoBanjir 实时水位和 15 分钟轮询。
- 历史洪水热点/实时警报地图图层。
- 历史月降雨柱状图和独立风险等级卡片。
