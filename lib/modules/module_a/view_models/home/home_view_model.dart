import 'package:flutter/material.dart';
import 'package:locate_my/modules/module_a/repositories/home/home_repository.dart';
import 'package:locate_my/modules/module_a/models/home/home_stats.dart';

class HomeViewModel extends ChangeNotifier {
  final HomeRepository _repository = HomeRepository();

  HomeStats? _stats;
  bool _isLoading = false;
  String? _error;
  DateTime? _lastRefreshTime;

  HomeStats? get stats => _stats;
  bool get isLoading => _isLoading;
  String? get error => _error;
  DateTime? get lastRefreshTime => _lastRefreshTime;

  static const Duration refreshCooldown = Duration(minutes: 1);

  bool get isRefreshLocked {
    if (_lastRefreshTime == null) return false;
    return DateTime.now().difference(_lastRefreshTime!) < refreshCooldown;
  }

  int get secondsUntilUnlock {
    if (_lastRefreshTime == null) return 0;
    final diff = refreshCooldown - DateTime.now().difference(_lastRefreshTime!);
    return diff.inSeconds > 0 ? diff.inSeconds : 0;
  }

  Future<void> loadStats({bool force = false}) async {
    if (force && isRefreshLocked) {
      _error = '请稍后再试，刷新频率限制为每分钟一次';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _stats = await _repository.getHomeStats(forceRefresh: force);
      if (force) {
        _lastRefreshTime = DateTime.now();
      }
    } catch (e) {
      _error = '加载宏观数据失败，部分指标可能暂不可用';
      debugPrint('HomeRepository Error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
