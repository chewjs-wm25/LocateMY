# Application Shell Java 可读性重构记录

日期：2026-09-17  
范围：Application Shell（`lib/app/`）的 Java 阅读习惯等价重构；不改变 `SHELL-001` 公开契约。

## 重构结果

完成。公开方法、构造函数形状、结果类型、异步顺序和账户范围行为保持兼容。

| 文件 | 结论 |
| --- | --- |
| `lib/app/application_shell.dart` | 已符合；canonical public seam 未修改。 |
| `lib/app/src/application/shell_runtime.dart` | 已改写：Getter、提前返回、异步结果和 intent/contribution binding 查找均改为显式类型、完整函数体与普通循环。 |
| `lib/app/src/domain/shell_routes.dart` | 已改写：显式构造初始化、完整 `matches`/`decode` 方法。 |
| `lib/app/src/domain/shell_state.dart` | 已符合；不可变状态对象保持不变。 |
| `lib/app/src/presentation/shell_view_model.dart` | 已改写：显式构造注入、监听回调与委托方法完整展开。 |
| `lib/app/src/presentation/shell_host.dart` | 已改写 Shell 自有的构造、状态分支、错误映射及任务 binding 查找；保留声明式 Widget 树、Navigator page 列表和框架回调。 |
| `test/support/fake_application_shell.dart` | 已改写：显式泛型队列和完整 async 方法体。 |

`lib/app/app.dart`、`shell_host.dart` 的 Home / Map 装配和视觉改动，以及对应 `test/app/home_shell_test.dart`、`map_shell_test.dart`、`map_privacy_test.dart`，是并行 Feature 已存在的工作。本次保留它们，不改变其语义或装配边界；`app.dart` 仍是后续 composition-root 协调项。

必要 Dart/Flutter 例外：sealed 类型的类型检查、`const` 不可变快照、Stream/Navigator/Widget 回调及声明式 Widget 树保留，以维持空安全、穷尽性、生命周期和框架行为。

## 兼容性与验证

在当前工作区基线执行：

- `dart format`（本次 Shell 文件）：通过。
- `flutter analyze lib/app test/app test/support/fake_application_shell.dart`：零问题。
- `flutter test test/app`：27 个测试全部通过；覆盖门控、同账户 scope、登出/重试、Tab/返回、贡献、语言、Home 和 Map 接线。
- `flutter build apk --debug`：通过，生成 `build/app/outputs/flutter-apk/app-debug.apk`。
- `git diff --check`：通过。

构建期间仅出现 Gradle 关于未来 Java native-access 行为的环境警告；没有编译或测试失败。

## 集成与阻塞

- 本期集成：不适用。本任务是等价可读性重构，未重新声明 Shell 已 `Implemented` 或 `Integrated`。
- 后续集成：Home/Map 和其他 Feature 继续由各 owning Wave 接入 `SHELL-001`；composition root 的共享接线由 Owner A 协调。
- 当前阻塞：无。
