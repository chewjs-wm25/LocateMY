# 仓库层：社会经济组件

## 数据源
- **OpenDOSM**：`hh_income_district` 数据集。

## 方法
- `getIncomeStats(String districtId)`：获取中位数和基尼系数数据。

## 策略
- **错误处理**：如果缺少特定地区的数据，则优雅地回退到州级平均值。
