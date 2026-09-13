# 模型层：基础设施组件

## 实体
- `InfrastructureData`：
    - `waterCoverage`：浮点数（供水覆盖率）。
    - `electricityCoverage`：浮点数（供电覆盖率）。
    - `sanitationCoverage`：浮点数（卫生设施覆盖率）。
    - `hospitalBeds`：整数（病床数）。
    - `schoolCount`：整数（学校数量）。

## DTO
- `AmenitiesResponse`：`hh_access_amenities` 的映射。
- `HealthResponse`：`hospital_beds` 的映射。
