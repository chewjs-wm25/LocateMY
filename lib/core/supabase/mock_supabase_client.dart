import 'package:supabase_flutter/supabase_flutter.dart';

/// 此类以前是 Mock 实现，现在已重构为真实 Supabase 客户端的包装器。
/// 它保留了原始的方法签名，以最小化对 Repository 层的破坏。
class MockSupabaseClient {
  static final MockSupabaseClient _instance = MockSupabaseClient._internal();
  factory MockSupabaseClient() => _instance;
  MockSupabaseClient._internal();

  SupabaseClient get _client => Supabase.instance.client;

  /// 获取数据库查询构建器
  SupabaseQueryBuilder from(String table) => _client.from(table);

  /// 执行 RPC 函数
  Future<dynamic> rpc(String function, {Map<String, dynamic>? params}) async {
    try {
      final response = await _client.rpc(function, params: params);
      return response;
    } catch (e) {
      // 在生产环境中应有更健壮的错误处理
      rethrow;
    }
  }

  /// 获取认证客户端
  GoTrueClient get auth => _client.auth;
}
