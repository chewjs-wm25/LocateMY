# 模型层：公共交通组件

## 实体
- `TransitStation`：
    - `id`：字符串。
    - `name`：字符串。
    - `type`：字符串（巴士/轻快铁 LRT/捷运 MRT）。
    - `coordinates`：经纬度。
- `TransitRoute`：
    - `lineName`：字符串（线路名称）。
    - `color`：字符串（颜色）。

## DTO
- `GTFSStopDTO`。
- `GTFSRouteDTO`。
