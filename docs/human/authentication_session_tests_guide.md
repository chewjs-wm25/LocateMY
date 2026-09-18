# authentication_session 测试代码入门

本文对应 `test/features/authentication_session/supabase_authentication_session_adapter_test.dart`，按 2026-09-16 的代码讲解。

## 1. 测试代码是做什么的？

你平时运行 App，输入邮箱和密码，再观察能否登录。这是人工检查。

这里的测试把检查过程写成 Dart 代码：准备条件 → 调用方法 → 检查结果。以后修改登录模块，可以重复运行这些检查，发现原本正常的行为是否被改坏。

例如，“没有保存过登录会话时，恢复登录应返回未登录，而且不应该发送网络请求”。测试会同时检查这两件事。

`lib/` 中的代码提供 App 功能；这个 `_test.dart` 文件由测试工具运行，用来检查功能。它不会给 App 增加页面或按钮。

## 2. 它测试哪段功能？

被测试的类是：

```text
lib/features/authentication_session/src/data/
  supabase_authentication_session_adapter.dart
```

`SupabaseAuthenticationSessionAdapter` 负责调用 Supabase 客户端，再把返回结果转换成 LocateMY 自己的结果类型：

| 方法 | 用途 |
| --- | --- |
| `restoreSession()` | 恢复并核验已有登录会话 |
| `signIn()` | 使用邮箱和密码登录 |
| `register()` | 注册账户，必要时写入可选的用户名资料 |
| `signOut()` | 退出当前设备上的登录 |
| `watchSession()` | 持续通知登录状态变化 |
| `retryOptionalProfile()` | 单独重试此前未成功写入的用户名资料 |

这里的 session（会话）可以理解为“客户端持有的登录凭据和相关用户信息”。它可能过期，也可能被远端拒绝；存在缓存并不等于一定可以恢复登录。

先认识三个返回类型：

| 类型 | 表达的意思 |
| --- | --- |
| `AuthenticatedSession` | 已取得可用登录身份，包含账户信息 |
| `UnauthenticatedSession` | 没有登录会话 |
| `SessionUnavailable` | 当前无法取得可用会话，附带失败原因 |

`SessionUnavailable` 与“没有登录过”不同。例如断网时可能有缓存，但无法完成核验。`retryableUnavailable` 表示可以稍后重试，`remoteRejected` 表示远端拒绝了会话。

这些结果类型定义在 `lib/features/authentication_session/src/domain/authentication_models.dart`。

## 3. 为什么不用真实账户和服务器？

这个文件使用真实的 `SupabaseClient`，但通过 `httpClient: MockClient(...)` 替换 HTTP 通信。

调用过程是：

```text
测试调用 adapter.signIn() 等方法
  → 项目的 adapter 调用 Supabase SDK
  → SDK 发出 HTTP 请求
  → MockClient 接住请求
  → 返回测试预设的数据或异常
  → adapter 处理结果
  → expect 检查结果
```

`https://auth.example.com`、`sb_publishable_test`、邮箱、密码和 token 都是测试数据。HTTP 请求由 MockClient 处理，不会访问真实 Supabase 项目，也不会创建真实账户。

这样可以随时模拟密码错误、服务器拒绝、断网、资料写入失败，且不依赖真实服务的状态。这些测试检查的是 adapter 与 SDK 配合时的行为；它们不能证明真实项目的数据库权限、邮件发送、网络服务或 App 页面全部正常。

## 4. 先读懂一个最简单的测试

第 83–86 行：

```dart
test('no cached session needs no network', () async {
  expect(await adapter.restoreSession(), isA<UnauthenticatedSession>());
  expect(requests, isEmpty);
});
```

- `test('描述', 函数)`：登记一项检查；描述会显示在运行结果里。
- `adapter.restoreSession()`：调用真正需要检查的方法。
- `async`、`await`：这个方法需要异步完成，测试要等它返回再判断。
- `expect(实际结果, 预期条件)`：断言；条件不满足时测试失败。
- `isA<UnauthenticatedSession>()`：检查结果属于这个类型。
- `isEmpty`：检查集合为空；这里表示没有 HTTP 请求。

你可以把它读成：“恢复会话的结果必须是未登录，且请求记录必须为空。”

`expect` 不会帮被测代码修正结果，它只检查结果。失败通常意味着行为与预期不一致，也可能是测试本身或运行环境需要检查。

## 5. 每个测试开始前，环境如何准备？

文件的 `main()` 是测试入口；`TestWidgetsFlutterBinding.ensureInitialized()` 初始化 Flutter 测试环境。这里没有 `testWidgets`、界面绘制或点击操作，因此不是页面测试。

`late` 表示变量稍后赋值。这几个共享变量在每个测试的 `setUp()` 中重新准备：

```dart
setUp(() {
  requests = [];
  respond = (_) async => jsonResponse(jsonEncode(user()), 200);
  // 创建带 MockClient 的 client，再创建 adapter。
});
```

- `requests`：记录 SDK 发出的请求，方便检查请求数量、路径和参数。
- `respond`：规定“这次模拟服务器如何回应”，各测试可以重新赋值。
- `client`：带模拟 HTTP 通信的 Supabase 客户端。
- `adapter`：被测试的项目类。

`respond` 默认返回用户 JSON 和状态码 200。`(_)` 的下划线表示不需要使用这个参数。

`autoRefreshToken: false` 关闭后台定时自动刷新，减少对测试时序的干扰；这不等于 SDK 在读取过期会话时完全不会刷新。`authFlowType: AuthFlowType.implicit` 是此测试客户端的配置，初学时不必先研究认证流程。

每个测试完成后，`tearDown()` 调用 `client.dispose()` 清理客户端资源。需要监听 Stream 的测试还会取消自己的订阅。

执行顺序可以理解为：

```text
setUp → 测试 A → tearDown
setUp → 测试 B → tearDown
setUp → 测试 C → tearDown
```

所以 A 中设置的断网响应不会直接成为 B 的默认响应。

## 6. 文件开头的辅助函数

### `jsonResponse(body, status)`

制作模拟 HTTP 响应。`body` 是响应文本，`status` 是状态码，还附带 JSON 内容类型及 SDK 使用的 API 版本响应头。

本文件模拟的状态码包括：200 成功、201 创建成功、204 成功且无响应内容、400 请求错误、401 会话被拒绝、403 资料写入被拒绝、422 密码不符合要求、429 请求限流、503 服务不可用。

### `user(confirmed: ...)`

制作用户资料的 Dart Map，`jsonEncode` 再把它变成 JSON 文本。

`confirmed: false` 时不添加 `email_confirmed_at`。特别注意：模拟数据里的 `user_metadata.email_verified` 仍为 true。第 88 行的测试因此可以检查 adapter 是否读取 Auth 返回的 `email_confirmed_at`，而不是误用 metadata 字段判断邮箱确认。

### `session(expired: ...)`

制作会话数据。`expired: false` 时，token 的 `exp` 是一小时后；`expired: true` 时是一小时前。

这里用 JSON、UTF-8 和 Base64URL 拼出 SDK 能读取过期时间的 token 形状。它没有真实签名，不是真正可用的登录凭据，也没有测试服务器的签名验证。

### `seed(expired: ...)`

把模拟会话放入 SDK，制造“客户端已有会话”的起点。随后清空 `requests`，使后续断言主要关注被测操作的请求，而不是准备阶段的请求。

这一步操作的是测试客户端，不是在手机上创建真实登录缓存。

## 7. 用断网测试理解“准备、执行、检查”

第 97–102 行：

```dart
test('offline restore cannot authorize cached identity', () async {
  await seed();
  respond = (_) async => throw TimeoutException('offline');
  final result = await adapter.restoreSession() as SessionUnavailable;
  expect(result.failure, SessionFailure.retryableUnavailable);
});
```

1. **准备**：`seed()` 放入已有会话；`respond` 改成抛出超时异常，模拟断网。
2. **执行**：调用真实的 `restoreSession()`，让它处理这次失败。
3. **检查**：结果必须是 `SessionUnavailable`，失败原因必须是可以重试的不可用。

`as SessionUnavailable` 是类型转换，方便访问 `failure`。如果方法实际返回别的类型，转换就会失败，测试也会失败。

这项测试保护的是项目的行为：“有缓存但无法核验身份时，不能直接恢复成已登录。”测试通过表示正确处理了这个模拟失败场景，并不是表示成功联网。

## 8. 15 个测试分别检查什么？

| 测试起始行 | 场景 | 主要检查 |
| --- | --- | --- |
| 83 | 没有缓存会话 | 返回未登录，不发送请求 |
| 88 | 缓存与远端的邮箱确认信息不同 | 请求 `/auth/v1/user`，采用远端的未确认状态 |
| 97 | 恢复时断网 | 返回可重试的会话不可用，不授权缓存身份 |
| 104 | 原会话过期，模拟刷新成功 | 最终能恢复身份，最后请求用户资料 |
| 119 | 登录凭据错误 | 映射成 `SignInFailure.invalidCredentials` |
| 131 | 注册返回用户但没有会话 | 要求邮箱验证；未提供用户名时跳过资料，不请求 profiles |
| 147 | 注册成功，但 profiles 写入被拒绝 | 保留注册成功和账户身份，同时报告资料权限失败 |
| 165 | 当前设备退出 | 请求参数 `scope=local`，客户端会话清空 |
| 173 | 空登录输入、两次注册密码不一致 | 返回拒绝，不发送 Auth 请求 |
| 189 | 订阅会话变化后退出 | 先收到已登录快照，再收到未登录快照 |
| 201 | 远端拒绝已有会话 | 返回 `remoteRejected`，不授权缓存身份 |
| 211 | 过期会话无法恢复，模拟服务不可用 | 返回可重试的会话不可用 |
| 223 | 恢复请求发出后，用户先退出 | 旧请求随后成功，也不能恢复旧身份 |
| 235 | 单独重试注册资料 | 重试成功后清除待重试状态，再次调用跳过 |
| 258 | 登录限流、注册密码太弱 | 前者返回可重试，后者返回输入错误 |

测试名称描述的是意图；实际覆盖程度由准备步骤和断言决定。例如第 104 行在 `seed()` 后清空了请求记录，没有直接断言刷新请求的路径和次数，因此不能据此认为完整的刷新调用顺序已经逐项验证。

## 9. 两段稍难的异步代码

### `watchSession()` 与 Stream

`Future` 通常给出一次结果；`Stream` 可以陆续给出多次结果。

第 189 行的测试用 `listen(snapshots.add)` 将每次状态存入列表，再用 `snapshots.last` 检查最新状态。结束时 `subscription.cancel()` 取消监听。

两次等待 30 毫秒是为了让异步通知有机会送达，不是网络请求耗时标准。固定等待依赖调度时机，机器忙时可能影响稳定性。

### `Completer` 与“迟到的响应”

第 223 行用 `Completer<http.Response>()` 手动控制请求何时完成：

```text
开始恢复会话，请求挂起
  → 用户退出成功
  → complete(...) 放行此前的用户响应
  → 检查旧响应不能重新恢复身份
```

`response.future` 是等待结果的 Future；`response.complete(...)` 才提供结果。这可以精确制造普通手动操作不容易重复的先后顺序。

`Future.delayed(Duration.zero)` 让出一次异步执行机会，使恢复请求能够先发出。

## 10. 如何运行？

在项目根目录 `/home/AC79/Desktop/LocateMY` 打开终端。

运行这个文件：

```bash
flutter test test/features/authentication_session/supabase_authentication_session_adapter_test.dart
```

只运行断网这一项：

```bash
flutter test test/features/authentication_session/supabase_authentication_session_adapter_test.dart --plain-name "offline restore cannot authorize cached identity"
```

逐行显示测试名称，便于阅读：

```bash
flutter test test/features/authentication_session/supabase_authentication_session_adapter_test.dart --reporter expanded
```

运行该目录或全部测试：

```bash
flutter test test/features/authentication_session
flutter test
```

这些测试不需要启动 Android 模拟器、不需要真实 Supabase 项目的 URL 或 key。首次准备开发环境时需要已安装 Flutter 和项目依赖；缺少依赖可先执行 `flutter pub get`。依赖下载可能需要联网，与测试访问真实 Auth 服务是两回事。

本项目已经在 `pubspec.yaml` 的 `dev_dependencies` 中配置了 `flutter_test` 和 `http`，无需再次添加。

测试输出中 `+15` 表示通过 15 项；`All tests passed!` 表示本次所选测试全部通过。失败时，先看测试名、`Expected`（预期）、`Actual`（实际）和堆栈指向的行。

这些运行方式及 `test` / `expect` 的基础用法可参阅 [Flutter 官方单元测试入门](https://docs.flutter.dev/cookbook/testing/unit/introduction)。

## 11. 如何开始练习？

建议先运行第 83 行的测试，再读第 97 行的断网测试，最后读第 119 行的密码错误测试。每次都问自己：准备了什么条件？调用了哪个方法？检查了什么结果？

可以临时把第 83 行预期的 `UnauthenticatedSession` 改为 `AuthenticatedSession`，只运行这一项，观察失败输出，再恢复原代码。这个练习只改变测试预期，不应修改生产代码来迎合错误预期。

以后增加测试时，在 `main()` 内添加新的 `test(...)`，复用现有 `setUp`，设置 `respond`，调用 adapter，再断言对使用者有意义的结果。例如新增一种服务器错误的处理，就为这种错误准备响应并检查它应返回的失败类型。

测试适合在修改认证代码前后运行：先确认现有起点，再检查修改是否破坏已有行为。全部通过只说明这些场景符合预期，不代表所有可能情况都已覆盖。

## 12. 与 `FakeAuthenticationSession` 的区别

`test/support/fake_authentication_session.dart` 是供其他测试使用的辅助实现，不属于这个目录，也不是这 15 项测试使用的对象。

本文件测试真实 adapter，通过 MockClient 模拟服务器；其他模块可以用 `FakeAuthenticationSession` 直接提供“登录成功”“恢复未登录”等结果，专注检查它们怎样处理这些结果。

两种方式替换的层次不同：前者保留 adapter 和 Supabase SDK 的执行过程；后者直接替换 `AuthenticationSession` 接口的实现。
