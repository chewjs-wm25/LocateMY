import 'dart:async';

import 'package:flutter/foundation.dart';

import '../application/shell_runtime.dart';
import '../domain/shell_state.dart';

final class ShellViewModel extends ChangeNotifier {
  final ShellRuntime runtime;
  late final StreamSubscription<ShellState> _subscription;
  ShellViewModel(ShellRuntime runtime) : runtime = runtime {
    _subscription = runtime.changes.listen((ShellState state) {
      notifyListeners();
    });
  }

  ShellState get state {
    return runtime.state;
  }

  Future<void> initialize() {
    return runtime.initialize();
  }

  Future<void> retry() {
    return runtime.retry();
  }

  Future<void> signOut() {
    return runtime.signOut();
  }

  void selectTab(ShellTab tab) {
    runtime.selectTab(tab);
  }

  void back() {
    runtime.back();
  }

  void openAccountTask() {
    runtime.openAccountTask();
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
