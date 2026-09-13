# 仓库层：HomeRepository

## 职责
负责从外部 API（如 OpenDOSM, World Bank, MetMalaysia）获取宏观数据，并进行初步的解析和缓存处理。

## 接口 (API)
- `getMacroEconomicStats()`: 从 Data.gov.my 或 OpenDOSM 获取最新的 GDP、CPI 和失业率数据。
- `getSeasonalClimateStatus()`: 从 MetMalaysia 或相关天气 API 获取当前季风状态。
- `getMacroSummary()`: 整合以上数据并返回 `HomeDataModel`。

## 数据源
- **OpenDOSM API**: 核心经济与就业指标。
- **World Bank API**: 长期 GDP 趋势与基尼系数对比。
- **MetMalaysia**: 季风季节性数据。

## 策略
- **缓存策略**: 宏观数据更新频率较低（月度或季度），应实施较长时间的本地缓存（如 24 小时或更久），仅在用户手动刷新时通过网络获取。
- **降级策略**: 如果 API 请求失败，返回上一次成功的缓存数据或静态的默认参考值。
