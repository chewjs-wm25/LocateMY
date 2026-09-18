# Account Privacy Java 可读性重构记录

日期：2026-09-17  
范围：Account Privacy 的单 Feature 可读性重构；不重新验收模块功能，也不宣告 `Integrated`。

## 结果

完成。公开入口 `PRIVACY-001` 的 import、公开 declaration、参数名称、返回类型、异步时序和可观察行为均保持兼容。

| 文件 | 结论 | 本次处理 |
| --- | --- | --- |
| `lib/features/account_privacy/account_privacy.dart` | 已改写 | 工厂与 dispose 改为完整函数体、显式 coordinator 局部变量。 |
| `src/domain/account_privacy_models.dart` | 已改写 | 构造参数、字段初始化关系均显式。 |
| `src/application/account_scope_store.dart` | 已改写 | checkpoint 构造初始化关系显式。 |
| `src/application/account_privacy_coordinator.dart` | 已改写 | 展开 cascade、条件表达式和 pattern-switch；注册、恢复、open、close、逐 participant 清理的中间类型与分支显式。 |
| `src/data/account_scope_journal.dart` | 已改写 | JSON phase/载荷选择与文件操作局部变量显式。 |
| `test/features/account_privacy/*.dart` | 已改写 | 专属 participant helper 与认证参与者测试改为显式类型、完整函数体和顺序分支。 |
| `test/support/fake_account_privacy.dart` | 已改写 | fake 的队列类型、读取和 close 行为改为显式写法。 |
| `tool/account_privacy_device.dart` | 已改写 | 设备 harness 的代理构造、participant 清理、状态更新、列表构建和主要本地变量改为显式写法。 |

保留的 Dart/Flutter 写法仅限必要的 `async`/`await`、集合展开（用于向 composition 注入 participant）、Flutter widget 声明和测试框架回调；这些写法不会隐藏业务执行顺序。

## 验证

- `dart format lib/features/account_privacy test/features/account_privacy test/support/fake_account_privacy.dart tool/account_privacy_device.dart`：通过。
- `flutter test test/features/account_privacy`：20 个测试通过。
- `flutter analyze lib/features/account_privacy test/features/account_privacy test/support/fake_account_privacy.dart tool/account_privacy_device.dart`：无 error；21 个 `prefer_initializing_formals` info。这些信息来自项目规范第 7 节要求的“显式参数类型 + 初始化列表”写法，不改变行为。
- `flutter build apk --debug --target tool/account_privacy_device.dart`：通过，生成 debug APK。
- `git diff --check`：通过。

## 集成与阻塞

本期集成：不适用；本任务只做可读性等价重构，未重新执行跨 Owner 验收。  
后续集成：沿用 Account Privacy Development Contract 第 5.1 节的既有责任与最迟 Wave。  
当前重构阻塞：无。
