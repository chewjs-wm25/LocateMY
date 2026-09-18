# 仓库层：生活开销组件

## 数据源
- **Data.gov.my**：`pricecatcher`, `cpi_core` 数据集。
- **本地缓存**：用于存储每日价格快照的 SQLite/Hive。

## 方法
- `getPricesByDistrict(String districtId)`：从 PriceCatcher 获取近期价格。
- `getNearbyPremises(double lat, double lon, double radius)`：利用 `lookup_premise` 数据集的坐标信息，在本地进行 Haversine 空间筛选。
- `getCPI(String stateId)`：获取州级消费者价格指数用于基准调整。
- `calculateLifestyleBudget(double currentBudget, String originId, String targetId)`：根据两地 CPI 比例计算建议预算。

## 策略
- **缓存**：在本地存储每日价格数据，以避免触及 Data.gov.my 的速率限制。
- **聚合**：在仓库层进行繁重的数据处理，向视图模型层返回简洁的模型。
