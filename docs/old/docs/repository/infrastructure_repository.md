# 仓库层：基础设施组件

## 数据源
- **Data.gov.my**：`hh_access_amenities`, `hospital_beds`, `school_enrolment`。

## 方法
- `getInfrastructureData(String districtId)`：并行获取所有设施数据集。

## 策略
- **批处理**：使用 `Future.wait` 并发触发多个 Data.gov.my 请求，以减少 UI 加载时间。
