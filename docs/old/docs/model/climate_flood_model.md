# 模型层：气候与水灾风险组件

## 实体
- `WeatherForecast`：
    - `date`：日期时间。
    - `condition`：字符串（如：雨、晴）。
    - `tempMin/Max`：浮点数。
- `FloodAlert`：
    - `stationName`：字符串（站点名称）。
    - `waterLevel`：浮点数（水位）。
    - `severity`：枚举（正常、警告、警报、危险）。

## DTO
- `MetMalaysiaForecastDTO`。
- `JPSAlertDTO`。
