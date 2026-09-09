# 房产对比页与回收站页

代码：`lib/modules/module_b/views/property/property_comparison_screen.dart`、
`lib/modules/module_b/views/property/recycle_bin_screen.dart`

## 已完成

- 对 2–3 个已选房产展示价格、评分、水灾历史、安全分数、隐患数及季风检查项对比表。
- 回收站展示软删除记录，可逐条恢复或确认后清空。

## 部分完成

- 对比结果仅用于当前 UI，没有保存为“历史对比”。
- 回收站仅为内存列表，不具备跨会话恢复能力。

## 未完成/差异

- 没有永久删除单条记录、自动清理期限、对比结论/权重配置。
- 没有把对比记录写入账户中心的“保存的对比”。

