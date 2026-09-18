# 仓库层：公共交通组件

## 数据源
- **GTFS Feeds**：Prasarana、KTMB 和 myBAS 的静态文件。
- **本地空间数据库**：PostGIS 或本地 Spatialite。

## 方法
- `getStationsNearby(double lat, double lng, double radius)`：对交通节点进行空间查询。
- `getRoutesForStation(String stationId)`：检索相关的交通线路。

## 策略
- **预打包**：由于更新频率较低，在应用资产中预打包 GTFS 静态数据，或在首次运行时下载。
