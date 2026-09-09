import 'package:supabase_flutter/supabase_flutter.dart';

/// 真实 Supabase 客户端管理器
class SupabaseClientManager {
  static final SupabaseClientManager _instance =
      SupabaseClientManager._internal();
  factory SupabaseClientManager() => _instance;
  SupabaseClientManager._internal();

  SupabaseClient get client => Supabase.instance.client;

  /// 获取数据库查询构建器
  SupabaseQueryBuilder from(String table) => client.from(table);

  /// 执行 RPC 函数
  Future<dynamic> rpc(String function, {Map<String, dynamic>? params}) async {
    return await client.rpc(function, params: params);
  }

  /// 获取认证客户端
  GoTrueClient get auth => client.auth;
}
