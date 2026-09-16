# Geographic Context · Wave 1 实现验收

日期：2026-09-16（Asia/Singapore）。责任 Owner：B；执行：本任务实现 AI。
依据：[开发与完成判定规范](../design/development-standard.md)第 3–5 节、
[owning contract](../design/modules/geographic-context.md)第 5.1 节及
[Issue #24](https://github.com/chewjs-wm25/LocateMY/issues/24)。

## 1. 模块实现：Implemented

Geographic Context 是无页面的 shared module；本期验证入口为公开 `GeographicContext.resolve`，
生产装配使用原有 `createGeographicContext(SupabaseClient)`。

修复与确认：

- 消费真实 RPC 的平铺 `state` / `district` 文本行；校验全部候选的 ID、名称和完整 provenance，包括 `geometry_transform`。
- 混合来源/版本/导入批次、字段缺失/错类型、相对 URI、无时区或非法日期、损坏的成功 JSON 均返回 `versionUnverifiable`，不生成猜测区域。
- district 按 `boundary_id` 保留完整稳定候选；reporting state 按不同州去重分类。同州多区保留 district ambiguous + state resolved。
- 返回 map/list 使用不可变快照；固定本次请求 levels。生产实现不再永久缓存旧版本、零覆盖或失败。
- 无会话、未确认邮箱及匿名登录不调用 RPC；请求完成时已改变的会话使响应不可用。退出后的晚到响应和后续读取均不会发布旧成功。
- 网络/超时映射 `sourceUnavailable`；认证/权限映射 `scopeUnavailable`；合法零行才是 `noCoverage`。恢复调用重新读取来源。
- 保留契约中的 const request 声明，将非空检查放到运行入口，避免 const 构造时执行不可常量求值的 Set.length 断言。
- 领域模型不依赖 Supabase SDK；Application 依赖内部 repository seam，Data Adapter 隔离 SDK。跨模块公开入口及结果声明保持原形。
- `http 1.6.0` 从 dev dependency 调整为直接依赖，以明确捕获运行时 HTTP transport 异常；版本未升级。

| 场景 | 本期验证结果与证据 |
| --- | --- |
| GEO-W1-01 单一行政区 | 公开入口验证 POST RPC、精确坐标参数、authenticated header、请求键和不可变结果；真实 Petaling 样本 district ID `10_5`，州为 Selangor，source/derived hash 与批准快照一致。见 [公开入口测试](../../test/modules/geographic_context/geographic_context_test.dart)、[真实环境记录](evidence/geographic-context-wave1-2026-09-16/live-test.txt)。 |
| GEO-W1-02 部分成功与零覆盖 | 同州多区保留州成功；provider fake 经同一 resolve seam 验证 state resolved + district noCoverage、键过滤及不可变快照。真实零候选时两层均 noCoverage，不声称 RPC 可产生 fake 的州成功/行政区零覆盖组合。见 [resolver/fake 测试](../../test/modules/geographic_context/geographic_context_resolver_test.dart)及真实环境记录。 |
| GEO-W1-03 边界、重叠、离岛 | 确定性多州及重复州样本验证稳定完整候选与州去重；真实边界点返回 2 个 district 候选，非主离岛返回 1 个。见公开入口测试、真实环境记录及两类设备记录。 |
| GEO-W1-04 权限、来源、版本、离线和恢复 | HTTP 测试覆盖全部必需字段在非首行缺失/空/错类型、混批、URI/日期错误、损坏 JSON、Socket/ClientException/Timeout、认证错误与恢复。真实 anon RPC deny；anon 底表 select deny；authenticated 两张底表 select/insert/update/delete deny（42501）。写权限探针用空 insert 或不存在的 version 条件，不改变边界资料。 |
| GEO-W1-05 并发、过期响应和版本 | 两个不同地点并发，旧响应晚到仍保留自身 levels/version，不污染新响应；同点后续调用读取新版本。真实退出重登恢复通过；退出期间晚到响应及退出后读取被拒绝。消费者对当前 A/B 端及版本的呈现筛选留到后续 Wave。 |
| GEO-W1-06 工程与设备 | 格式、分析、66 项测试、普通 debug APK 通过。两类设备各完成启动和强制停止后的重启，均 ALL PASS；包含成功、signed-out 失败、退出拒绝与重新登录恢复。见下面工程和设备证据。 |

### 工程验证

环境：Linux；Flutter 3.47.2 stable / Dart 3.13.2；OpenJDK 26.0.1。
真实开发项目为仓库已关联的 Supabase 项目；实际客户端只使用 publishable key。
代码基于 `0cd4c660eddfa869783c8dd6cc9bf003e5abe4f3` 加本任务工作树变更，未提交。
[代码版本记录](evidence/geographic-context-wave1-2026-09-16/code-version.txt)
保存本模块代码、测试、验证工具及依赖文件的 SHA-256，用于对应本次证据；
[环境记录](evidence/geographic-context-wave1-2026-09-16/environment.txt)保存具体工具及设备版本。

| 命令 / 操作 | 结果 | 记录 |
| --- | --- | --- |
| `dart format --output=none --set-exit-if-changed .` | exit 0；34 个 Dart 文件无格式变更 | [format](evidence/geographic-context-wave1-2026-09-16/format.txt) |
| `flutter analyze` | exit 0；No issues found | [analyze](evidence/geographic-context-wave1-2026-09-16/analyze.txt) |
| `flutter test --reporter expanded` | exit 0；66 项通过，2 项 opt-in live 默认跳过 | [tests](evidence/geographic-context-wave1-2026-09-16/tests.txt) |
| `python3 tool/verify_geographic_context_live.py --devices <Owner-A-adb-target> emulator-5554` | 真实 GEO live test 1 项另行通过；两个目标均启动/重启通过 | [live](evidence/geographic-context-wave1-2026-09-16/live-test.txt)、[device build](evidence/geographic-context-wave1-2026-09-16/device-build.txt) |
| `flutter build apk --debug`（上述 runner 自动执行） | exit 0；普通 APK 构建成功，扫描无本机高权限密钥或临时账户凭据 | [production build](evidence/geographic-context-wave1-2026-09-16/production-build.txt) |

Geographic Context 的确定性测试合计 16 项，包含 provider fake 测试。
默认跳过的两个 live test 分属 Authentication 和 Geographic Context；本任务已单独执行后者，
不把跳过当作真实环境通过。真实边界 sourceVersion 为批准的 DOSM commit
`21a78e98efd4cd9b022a27a1bf67d167076b7591`，sourceSha256 为
`3edb1022b2de371bba6b7afb9802b6fc6d747c86dbcc40abf2374a9134f3c561`，
derivedGeometrySha256 为 `929e7ce03417d284972f6550820806d0a29179f532b1c6c77f6bf5473bc1cb7f`。

### 设备验证

- Owner A 目标：SM-A528B 真机，无线 adb，Android 14 / API 34。
  [启动记录](evidence/geographic-context-wave1-2026-09-16/owner-a-device-launch.txt) ·
  [启动截图](evidence/geographic-context-wave1-2026-09-16/owner-a-device-launch.png) ·
  [重启记录](evidence/geographic-context-wave1-2026-09-16/owner-a-device-restart.txt) ·
  [重启截图](evidence/geographic-context-wave1-2026-09-16/owner-a-device-restart.png)。
- Owner B 目标：Android SDK emulator `sdk_gphone64_x86_64`，Android 16 / API 36。
  [启动记录](evidence/geographic-context-wave1-2026-09-16/owner-b-emulator-launch.txt) ·
  [启动截图](evidence/geographic-context-wave1-2026-09-16/owner-b-emulator-launch.png) ·
  [重启记录](evidence/geographic-context-wave1-2026-09-16/owner-b-emulator-restart.txt) ·
  [重启截图](evidence/geographic-context-wave1-2026-09-16/owner-b-emulator-restart.png)。

设备使用 [独立开发 harness](../../tool/geographic_context_device.dart)调用真实生产公开入口；
先验证真实已确认会话，只访问公共地理资料，不建立任何账户私有 Feature、缓存或队列。
它不是 Shell/Privacy 的联合门控证明。主应用真实 opened 门控的责任与期限见下表。
验证结束已恢复两台设备的普通应用 APK；临时已确认测试账户删除，临时 define 文件删除，`.env` 原内容恢复。
同 basename [HTML](geographic-context.html)从 Markdown 重新导出，并在生成时核对 17 个标题、
2 个 Dart fenced blocks、验收表和相对链接路径；未改变公开契约。

RPC 使用方式核对了 [Supabase Dart RPC 文档](https://supabase.com/docs/reference/dart/rpc)，
同时检查了当前锁定 SDK 中损坏成功 JSON 的异常映射；判断不依赖异常消息文字。

## 2. 本期集成

不适用：第 5.1 节没有截至 Wave 1 到期的跨模块联合场景。
本期已真实连接 Auth/RPC，Map 仅提供已合入的公开类型和合法固定样本。
本报告判定 Geographic Context 模块 Implemented；不单独判定整个 Wave 1 完成，
也不授予项目负责人保留的 Integrated 状态。

## 3. 后续集成

| 待接入及验证 | 主责 / 参与 | 最迟 Wave |
| --- | --- | --- |
| Shell/Privacy 的真实 opened 门控，退出/换号先关闭调用入口 | A 主责；B 参与 Geographic Context 的调用/失败验证 | 3 |
| Map 真实合法选点、absence 不调用、单点/A-B 引用和旧端晚到响应处理 | A 主责；B 参与 | 4 |
| Cost / Crime 只用对应 resolved 层级读真实指标；ambiguous/unavailable 不读；A/B 来源版本处理 | Cost：B；Crime：A；B 提供 Geo 联验支持 | 5 |
| Socio / Infrastructure 的真实统计读取、部分结果、各自回退/不补零、版本与过期结果处理 | B 主责；A 参与组合流程 | 6 |

## 4. 当前阻塞

无。GEO-W1-01 至 GEO-W1-06 的本模块责任均通过；未来联合项均有明确 Owner 和期限。
