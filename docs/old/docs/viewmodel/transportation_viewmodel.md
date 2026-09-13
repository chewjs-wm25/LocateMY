# 视图模型层：公共交通组件

## 状态定义
- `transitScore`：计算出的连通性分值。
- `nearbyStations`：带有距离信息的站点实体列表。
- `transitRoutes`：用于地图可视化的路径数据。

## 命令 / 方法
- `searchNearbyTransit(double lat, double lng)`：在本地数据库或 API 中触发空间搜索。
- `calculateConnectivityScore()`：连通性密度算法的实现。

## 数据转换
- 根据运营时间和班次筛选 GTFS 路线。
- 计算从用户坐标到站点的步行距离。
