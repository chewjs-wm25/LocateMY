import 'dart:async';

import 'package:flutter/foundation.dart';

import '../application/shell_runtime.dart';
import '../domain/shell_state.dart';

final class ShellViewModel extends ChangeNotifier {
  final ShellRuntime runtime;
  late final StreamSubscription<ShellState> _subscription;
  ShellViewModel(this.runtime) {
    _subscription = runtime.changes.listen((_) => notifyListeners());
  }
  ShellState get state => runtime.state;
  Future<void> initialize() => runtime.initialize();
  Future<void> retry() => runtime.retry();
  Future<void> signOut() => runtime.signOut();
  void selectTab(ShellTab tab) => runtime.selectTab(tab);
  void back() => runtime.back();
  void openAccountTask() => runtime.openAccountTask();
  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
