# 仓库层：气候与水灾风险组件

## 数据源
- **MetMalaysia API**：天气预报。
- **JPS InfoBanjir**：实时水位。

## 方法
- `getForecast(double lat, double lng)`：返回 7 天预报。
- `getFloodAlerts()`：返回活动警告。

## 策略
- **轮询**：应用处于活跃状态时，对 JPS 警报实施 15 分钟的轮询间隔。
