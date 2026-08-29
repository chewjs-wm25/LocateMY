# 模型层：生活开销组件

## 实体
- `PriceItem`：
    - `itemCode`：字符串（来自 PriceCatcher 的唯一标识符）。
    - `itemName`：字符串。
    - `price`：浮点数。
    - `premise`：字符串（零售场所）。
- `DifferentialResult`：
    - `totalChangePercentage`：浮点数。
    - `categoryBreakdown`：类别与分值的映射。

## DTO
- `PriceCatcherResponse`：`api.data.gov.my` PriceCatcher 接口的映射。

## 序列化
- 使用 `json_serializable` 进行 API 响应映射。
