---
kind: product-fact
language: zh-CN
canonical: true
---

# 统一生活篮子 v1

本资料是 LocateMY 单身成年人统一生活篮子的唯一版本化事实源。v1 的 11 项是 PriceCatcher 核心市场篮子，不是官方消费权重、营养建议或九类完整家庭预算；住房、交通和用户的额外生活开销仍由当前评估预案单独输入。

## v1 项目与数量

下列数量以 PriceCatcher `lookup_item` 的原始单位计月用量。它们在 v1 固定，不支持逐项数量或频次调整。导入审计必须验证每个 `item_code`、单位和全国代表价格可读；任何项目不可读时，按生活成本模型的缺失与覆盖规则处理，不能替代商品或臆造价格。

| item_code | 项目 | 单位 | 月数量 `q(i)` |
| --- | --- | --- | --- |
| 1 | AYAM BERSIH - STANDARD | 1kg | 2 |
| 16 | BETIK BIASA | 1kg | 2 |
| 118 | TELUR AYAM GRED A | 10 biji | 3 |
| 224 | SUSU SEGAR DUTCH LADY | 1 liter | 4 |
| 272 | ROTI SANDWICH GARDENIA ORIGINAL CLASSIC | 400 g | 4 |
| 904 | BERAS SUPER CAP RAMBUTAN 5% | 10 kg | 0.5 |
| 918 | MINYAK MASAK PAKET | 1kg | 2 |
| 1589 | GULA PUTIH BERTAPIS KASAR | 1kg | 1 |
| 1605 | GARAM HALUS BIASA | ±350g | 1 |
| 1645 | SERBUK KOPI CAP KAPAL API | 180 g | 1 |
| 1541 | SABUN PENCUCI SUNLIGHT | 1000 ml | 1 |

## 版本、权重与基准

版本标识为 `cost-basket-v1`。对一次固定导入快照，使用该快照的全国代表价格和上表数量计算 `BaseSpend12`；每项的 `w(i)` 是该项目的全国基准支出除以该版本 `BaseSpend12`。导入登记保存资料日期、篮子版本、全国代表价格、`BaseSpend12` 与完整性；这些值冻结为该导入批次的基准，不随客户端时间变化。

篮子变更必须创建新版本，不能改写 v1；A/B 只可比较同一篮子版本。

来源：项目负责人于 2026-09-14 批准本文件的首版项目、数量、权重和版本冻结规则为项目产品假设；官方 [PriceCatcher Item Lookup](https://data.gov.my/data-catalogue/lookup_item) 与项目中的 `lookup_item` 导入审计是实际 item-code/单位的执行证据。
