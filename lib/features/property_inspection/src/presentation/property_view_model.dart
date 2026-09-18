

import 'package:flutter/foundation.dart';

import '../domain/property_models.dart';
import '../application/property_service.dart';

final class PropertyPortfolioViewModel extends ChangeNotifier {
  final PropertyInspectionService service;
  final bool deleted;
  bool _disposed = false;
  int _revision = 0;
  bool busy = false;
  Object? error;
  List<PropertyInspectionRecord> records = const <PropertyInspectionRecord>[];
  PropertyPortfolioViewModel(
    PropertyInspectionService service, {
    bool deleted = false,
  }) : service = service,
       deleted = deleted;
  Future<void> load() async {
    final int revision = ++_revision;
    busy = true;
    error = null;
    notifyListeners();
    try {
      final List<PropertyInspectionRecord> result = await service.list(
        deleted: deleted,
      );
      if (_disposed || revision != _revision) {
        return;
      }
      records = result;
    } catch (failure) {
      if (_disposed || revision != _revision) {
        return;
      }
      error = failure;
    }
    if (!_disposed && revision == _revision) {
      busy = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _revision++;
    super.dispose();
  }
}

final class PropertyInspectionViewModel extends ChangeNotifier {
  final PropertyInspectionService service;
  final PropertyPhotoPicker? picker;
  bool busy = false;
  Object? failure;
  PropertyInspectionRecord? record;
  bool _disposed = false;
  int _loadRevision = 0;
  PropertyInspectionViewModel({
    required PropertyInspectionService service,
    PropertyPhotoPicker? picker,
  }) : service = service,
       picker = picker;
  Future<T?> perform<T>(Future<T> Function() action) async {
    if (busy || _disposed) {
      return null;
    }
    busy = true;
    failure = null;
    notifyListeners();
    try {
      final T result = await action();
      if (_disposed) {
        return null;
      }
      return result;
    } catch (error) {
      if (!_disposed) {
        failure = error;
      }
      return null;
    } finally {
      if (!_disposed) {
        busy = false;
        notifyListeners();
      }
    }
  }

  Future<PropertyInspectionRecord?> save(
    PropertyInspectionDraft draft, {
    String? id,
  }) {
    return perform<PropertyInspectionRecord>(() {
      return service.save(draft, id: id);
    });
  }

  Future<PropertyPickedPhoto?> pick(PropertyPhotoSource source) {
    return perform<PropertyPickedPhoto?>(() async {
      return picker?.pick(source);
    });
  }

  Future<void> load(String id) async {
    final int revision = ++_loadRevision;
    try {
      final PropertyInspectionRecord result = await service.read(id);
      if (_disposed || revision != _loadRevision) {
        return;
      }
      record = result;
      failure = null;
    } catch (error) {
      if (_disposed || revision != _loadRevision) {
        return;
      }
      failure = error;
    }
    if (!_disposed) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _loadRevision++;
    super.dispose();
  }
}
