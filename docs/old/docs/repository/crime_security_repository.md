# 仓库层：治安与犯罪组件

## 数据源
- **Data.gov.my**：`crime_district` 数据集。

## 方法
- `getCrimeStats(String districtId)`：检索各类犯罪数据。

## 策略
- **镜像**：由于 PDRM 数据每年更新一次，仓库应在调用 API 之前检查本地 JSON 更新。
