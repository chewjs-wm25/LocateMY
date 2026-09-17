# Home & Relocation Outlook Java 可读性重构

日期：2026-09-17

## 结果

完成。`HOME-001` 的公开类型、构造调用形状、返回结果、缓存/冷却语义和 Shell 意图调用均保持兼容。本次仅修改 Home & Relocation Outlook 的生产 Dart 文件；没有修改共享 Shell、Supabase schema、依赖或 lockfile。

## 覆盖清单

已审查 `lib/features/home_relocation_outlook/` 下全部 14 个手写 Dart 文件。主要改写位于：

- `home_relocation_outlook.dart`：将工厂创建和默认 SQLite opener 展开为具名局部对象与完整函数体。
- `src/application/home_service.dart`：将并发 load、结果遥测、可验证性、缓存回退和来源日期比较拆为具名的顺序步骤。
- `src/data/supabase_home_reader.dart`：将 RPC 错误分类展开为显式分支；仍只调用 `read_home_metrics`。
- `src/domain/home_scoring.dart` 和 `home_trends.dart`：将 percentile、加权、变化、字段读取和趋势历史构建从集合链/模式表达式展开为显式循环及中间值。
- `src/presentation/home_view_model.dart`、`home_trend_chart.dart` 和 `home_visual_style.dart`：将有逻辑的箭头函数、cascade、switch expression 和回调流程改为完整函数体与 if/else。

其余文件为不可变的契约模型、编解码映射、SQLite 映射或 Flutter 声明式 Widget 树。保留的集合/Widget 字面量、`async` callback、`const`、sealed pattern switch、`late final` 和 Flutter 生命周期写法是 Dart 类型安全或框架 API 所需；它们不改变对象职责或公开接口。

专属测试、fake 和 Android harness 已盘点。它们主要使用测试框架/Flutter 必需 callback、fixture collection 和 mock transport；本次未为纯风格新增测试缝或改变测试行为。

## 验证

在工作区当前未提交基线执行：

```text
dart format lib/features/home_relocation_outlook
flutter analyze lib/features/home_relocation_outlook test/features/home_relocation_outlook test/support/fake_home_relocation_outlook.dart tool/home_outlook_device.dart
flutter test test/features/home_relocation_outlook --reporter compact
flutter build apk --debug
```

格式检查无改动；静态分析无问题；35 个 Home 专属测试全部通过；debug APK 已成功构建。测试覆盖公开加载结果、错误映射、缓存、新旧资料保护、60 秒冷却、并发、趋势、页面刷新、无障碍与 Shell 探索意图。

## 集成与阻塞

本期集成：不适用；这是等价可读性重构，不改变既有 Home/Shell 接线。

后续集成：真实 Map 联验仍由 Owner A 在 Wave 4 完成，依据 owning contract 既有记录；本次未重新验收其状态。

当前阻塞：无代码重构阻塞。真实 Supabase/设备验收不因本次没有改变 Adapter 行为而重跑；该 Feature 的已有 live/device 证据继续适用。
