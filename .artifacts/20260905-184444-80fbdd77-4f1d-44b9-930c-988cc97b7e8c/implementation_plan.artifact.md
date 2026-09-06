# Supabase 真实对接与硬编码数据清理计划

本计划旨在将现有的模拟数据层替换为真实的 Supabase 后端集成，清理代码中所有的硬编码数据，并确保应用与 `docs/real_supabase_tables.md` 中定义的表结构保持一致。

## 用户评审确认

- **Supabase 凭据**: 请在 `lib/core/api_keys.dart` 中填写您的 `supabaseUrl` 和 `supabaseAnonKey`。
- **RPC 函数**: 本计划假设 Supabase 后端已部署 `match_police_district` 等 RPC 函数。
- **地理空间查询**: 涉及到经纬度匹配的部分将使用 Supabase PostGIS 能力。

## 提议的更改

---

### 1. 核心配置与初始化

#### [api_keys.dart](file:///D:/Work/Mobile Application/Assignment/lib/core/api_keys.dart)
- 添加 Supabase 连接信息常量。

```dart
class ApiKeys {
  static const String geoapify = '...';
  static const String supabaseUrl = 'YOUR_SUPABASE_URL';
  static const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';
}
```

#### [main.dart](file:///D:/Work/Mobile Application/Assignment/lib/main.dart)
- 在应用启动前初始化 Supabase。

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: ApiKeys.supabaseUrl,
    anonKey: ApiKeys.supabaseAnonKey,
  );
  runApp(...);
}
```

---

### 2. Supabase 客户端重构

#### [mock_supabase_client.dart](file:///D:/Work/Mobile Application/Assignment/lib/core/supabase/mock_supabase_client.dart)
- 彻底删除所有 Mock 数据类和逻辑。
- 将其重构为一个简单的包装器或直接导出 `SupabaseClient`，以最大限度减少对现有 Repository 代码的破坏。

```dart
import 'package:supabase_flutter/supabase_flutter.dart';

class MockSupabaseClient {
  SupabaseClient get _client => Supabase.instance.client;

  SupabaseQueryBuilder from(String table) => _client.from(table);
  Future<dynamic> rpc(String function, {Map<String, dynamic>? params}) => _client.rpc(function, params: params);
  GoTrueClient get auth => _client.auth;
}
```

---

### 3. 数据存储库 (Repositories) 更新

#### [cost_of_living_repository.dart](file:///D:/Work/Mobile Application/Assignment/lib/repositories/cost_of_living_repository.dart)
- 移除 `getComparisonData` 中的硬编码分类支出。
- 使用真实 `price_catcher` 和 `cpi_state` 表数据。

#### [security_repository.dart](file:///D:/Work/Mobile Application/Assignment/lib/repositories/security_repository.dart)
- 将 `crime_stats` 查询从 `police_district_id` 改为按 `district` (名称) 过滤。
- 移除硬编码的安全分数计算回退值。

#### [infrastructure_repository.dart](file:///D:/Work/Mobile Application/Assignment/lib/repositories/infrastructure_repository.dart)
- 移除硬编码的 `healthScore`、`eduScore` 等评分逻辑。
- 对接 `hospital_beds` 和 `teachers_district` 表以计算真实指数。

#### [socio_economic_repository.dart](file:///D:/Work/Mobile Application/Assignment/lib/repositories/socio_economic_repository.dart)
- 移除基于收入中位数的硬编码排名逻辑。
- 移除所有 fallback 常量。

### 6. 修复构建错误与功能补全

#### [budget_provider.dart](file:///D:/Work/Mobile Application/Assignment/lib/providers/budget_provider.dart)
- 补全 `renameScenario`、`deleteScenario` 和 `updateCurrentScenario` 方法，确保其与 Supabase 同步。
- 解决由于 `currentScenario` 可能为 null 导致的视图层调用问题。

#### [cost_of_living_view.dart](file:///D:/Work/Mobile Application/Assignment/lib/views/cost_of_living/cost_of_living_view.dart)
- 增加对 `currentScenario` 为 null 的防护处理（使用 `?.` 和空值判断）。

## 验证计划

### 自动化测试
- 运行 `flutter analyze` 确保类型匹配正确（特别是 Supabase 返回的 `List<Map<String, dynamic>>`）。

### 手动验证
- 检查调试控制台是否输出 Supabase 连接请求。
- 验证各页面（生活开销、安全评分、基础设施）在无网络或数据库为空时的占位符状态（而非硬编码数据）。
