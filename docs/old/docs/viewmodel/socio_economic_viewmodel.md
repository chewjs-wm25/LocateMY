# 视图模型层：社会经济组件

## 状态定义
- `incomeData`：所选地区的收入中位数/平均值。
- `giniCoefficient`：不平等程度衡量指标。
- `userPercentile`：用户输入收入所在的百分位。

## 命令 / 方法
- `fetchEconomicData(String districtId)`：获取 OpenDOSM 收入统计数据。
- `calculateUserPercentile(double income)`：将用户置于分布曲线上的逻辑。

## 数据转换
- 按照马来西亚标准 (RM) 格式化货币字符串。
- 根据最新的州级数据推算 B40/M40/T20 的分界线。
