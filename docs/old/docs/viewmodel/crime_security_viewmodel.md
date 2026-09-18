# 视图模型层：治安与犯罪组件

## 状态定义
- `selectedPoliceDistrict`：当前查看的警区。
- `historicalTrends`：过去 5 年的犯罪数据点列表。
- `crimeStructure`：当年的犯罪类别细分。
- `safetyScore`：计算出的安全得分。

## 命令 / 方法
- `loadDistrictData(String districtId)`：获取皇家警察 (PDRM) 数据并计算结构。
- `toggleCrimeFilter(CrimeCategory category)`：筛选图表显示内容。

## 数据转换
- 如有必要，将“警区 (Police District)”边界映射到“行政县 (Administrative District)”。
- 将犯罪数量按每 10 万人口进行归一化，以便进行对比。
