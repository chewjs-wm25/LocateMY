# <shared module 名称>

> 状态：`Draft`
> Owner：`A/B`
> 系统基线：`<commit>`
> 消费者：`<Feature...>`
> 最后更新：`YYYY-MM-DD`

本 Markdown 是本模块的唯一 Development Contract；同 basename HTML 仅为语义等价导出。

## 1. 建立理由与责任

- 必须跨 Feature 共享的状态、规则或入口：
- 不能由单一 Feature 拥有的原因：
- 明确不负责：
- 关联 Capability / 系统基线：

## 2. 依赖、消费者与文件边界

| 路径或消费者 | Owner | `create/modify/reuse` | 责任 / 使用目的 | 不负责 / 安全边界 |
| --- | --- | --- | --- | --- |
| `lib/core/<module>/<module>.dart` | | | 唯一公开入口 | |

仅冻结跨 Owner 文件和公开入口；内部文件拆分由 Owner 决定。

## 3. Public Interface

先说明每个 Interface 的 ID、消费者、生命周期、权限、副作用和失败恢复，再给出完整 caller-visible declaration。

```dart
// import 'package:locatemy/core/<module>/<module>.dart';
// 只放 declaration；不得写函数体、Widget 或 SDK mapping。
```

提供方先合并 declarations 并用真实 Adapter 测试；消费者只导入这一入口并以 fake 测试。

## 4. 用户结果与跨 Owner 流程

| 动作 | 成功 | 空/部分/失败 | 恢复 | 安全或可访问性 |
| --- | --- | --- | --- | --- |
| | | | | |
## 5. 数据与确定性规则

| 目的 | Schema 对象或事实源 | 访问边界 | 规则 ID、单位、边界与结果语义 |
| --- | --- | --- | --- |
| | | | |

## 6. 验收与 Ready Gate

| Capability / 消费者 / `AT-*` | 前置 | 操作 | 可观察结果 | Owner 测试 / 联合证据 |
| --- | --- | --- | --- | --- |
| | | | | |

- [ ] 成果可观察：正常、空、失败、离线/权限和恢复均明确。
- [ ] 边界可编译：唯一入口、完整 declarations、失败/lifecycle/权限和依赖无猜测。
- [ ] 资料可复现：对象、公式、单位、边界和来源均指向唯一事实源。
- [ ] 协作可验收：Owner、fake/Adapter、联合情景、变更协议明确；阻塞项为零且独立审查已完成。

## 7. Interface 变更协议

提供方说明原因和受影响消费者，全部消费者确认；同一 PR 更新 declarations、本 Contract、同名 HTML 与受影响测试。实质变化使本 Contract 退回 `Draft`，复审后恢复。

## 8. Change Log

| 日期 | 状态 | 原因 | 影响 | 批准者 |
| --- | --- | --- | --- | --- |
| | | | | |
