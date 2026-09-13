# 模型层：治安与犯罪组件

## 实体
- `CrimeRecord`：
    - `district`：字符串（地区）。
    - `year`：整数（年份）。
    - `category`：字符串（暴力/财产犯罪）。
    - `count`：整数（案件数）。
- `SafetyScore`：
    - `overallIndex`：浮点数（综合指数）。
    - `ratingLabel`：字符串（评级标签）。

## DTO
- `CrimeAPIResponse`：`crime_district` 数据集的 JSON 映射。
