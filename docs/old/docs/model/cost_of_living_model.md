# 模型层：生活开销分析 (Cost of Living Analysis)

## 核心实体 (Entities)

### 1. `BudgetScenario` (预算预案)
- `id`: UUID.
- `name`: 预案名称 (如 "家庭版", "独居版").
- `originPoskod`: 原住址邮编.
- `targetPoskod`: 目标地邮编.
- `items`: `List<BudgetItem>`.
- `totalOriginBudget`: 原住址总支出预估.
- `totalTargetBudget`: 目标地总支出预估.

### 2. `BudgetItem` (预算条目)
- `category`: 类别 (Housing, Food, Transport, Utilities, etc.).
- `originAmount`: 原住址金额.
- `targetAmount`: 目标地自动计算金额 (基于 CPI).
- `userAdjustedAmount`: 用户手动微调后的金额.

### 3. `Premise` (商家)
- `code`: 商家唯一代码 (`premise_code`).
- `name`: 商家名称.
- `address`: 地址.
- `lat`: 纬度.
- `lon`: 经度.
- `type`: 类型 (Hypermarket, Wet Market, etc.).

### 4. `PriceEntry` (价格条目)
- `itemCode`: 商品代码.
- `itemName`: 商品名称.
- `unit`: 单位 (KG, 10s, etc.).
- `price`: 成交价格.
- `premiseCode`: 关联商家代码.
- `date`: 采集日期.

## 数据传输对象 (DTOs)
- `PriceCatcherDTO`: 映射自 `data.gov.my` 的价格捕捉接口.
- `PremiseLookupDTO`: 映射自 `lookup_premise` 接口.

## 计算逻辑模型
- `LifestyleTranslationResult`:
    - `purchasingPowerIndex`: 购买力指数.
    - `savingsPotential`: 潜在节省金额.
    - `comparisonMatrix`: 两地各维度的 CPI 对比矩阵.
