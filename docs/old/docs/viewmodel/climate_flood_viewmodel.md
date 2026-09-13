# 视图模型层：气候与水灾风险组件

## 状态定义
- `weatherForecast`：天气预报实体列表。
- `activeAlerts`：水灾/天气警报列表。
- `floodHistory`：用于地图图层叠加的 GeoJSON 数据。

## 命令 / 方法
- `refreshForecast(double lat, double lng)`：获取 MetMalaysia 数据。
- `fetchFloodAlerts()`：向 JPS InfoBanjir 轮询实时状态。

## 数据转换
- 将天气代码转换为 UI 描述性图标。
- 按频率对历史水灾发生地进行分组，用于地图热力图渲染。
