# <Feature 名称>

> 状态：`Draft`
> Owner：`A/B`
> 系统基线：`<commit>`
> 依赖波次：`<编号>`
> 最后更新：`YYYY-MM-DD`

本 Markdown 是本 Feature 的唯一 Development Contract；同 basename HTML 仅为语义等价导出。

## 1. 用户成果与范围

- 首屏可观察完成定义：
- Capability：
- 包含：
- 不包含：
- 产品事实源：

## 2. 依赖、责任与文件边界

| 路径或模块 | Owner | `create/modify/reuse` | 责任 | 不负责 |
| --- | --- | --- | --- | --- |
| `lib/features/<feature>/<feature>.dart` | | | 唯一公开入口 | |

仅冻结跨 Owner 文件和公开入口；内部文件拆分由 Owner 决定。列出全部上游 contract、composition-root 接线和未决项。

## 3. Public Interface

设计公开 declaration 及实现手写 Dart 代码时，遵循[Java 阅读习惯约束](../development-standard.md#7-java-阅读习惯与-dart-可读性约束)。

每个 Interface 先给出 ID、消费者、生命周期、权限、副作用及失败恢复，再给出完整 caller-visible declaration。不得省略参数名、类型、sealed 分支或必要的 equality/immutability 语义。

```dart
// import 'package:locatemy/features/<feature>/<feature>.dart';
// 只放 declaration；不得写函数体、Widget 或 SDK mapping。
```

提供方先合并 declarations 并以真实 Adapter 测试；消费者只导入这一入口并以 fake 测试。列出实际消费的上游 Interface 及调用子集，不复制另一份有分歧的定义。

## 4. 用户行为与跨 Owner 流程

| 动作 | 成功 | 空/部分/失败 | 恢复 | 安全或可访问性 |
| --- | --- | --- | --- | --- |
| | | | | |
按调用顺序写联合流程；每一步注明 Owner、输入、结果和停止条件。

## 5. 数据与确定性规则

| 目的 | Schema 对象或事实源 | 访问边界 | 规则 ID、单位、边界与结果语义 |
| --- | --- | --- | --- |
| | | | |

字段、RLS、migration 和公式正文只链接唯一来源，不在此复制新版本。

## 6. 验收与 Ready Gate

开发前按 [统一开发规范](../development-standard.md#1-开发前固定验收范围)分配每项验收场景；补充所需依赖及用途、验证归属、证据要求、负责 Owner、最迟 Wave、本模块与联合证据的各自状态。联合场景拆出当期本模块子项。实现和 Wave 完成按该规范判定，以下 Ready Gate 只判断设计就绪。

| Capability / `AT-*` | 前置 | 操作 | 可观察结果 | Owner 测试 / 联合证据 |
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
