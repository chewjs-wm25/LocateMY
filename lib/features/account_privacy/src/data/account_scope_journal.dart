import 'dart:convert';
import 'dart:io';

import '../application/account_scope_store.dart';

// Only barrier identity/phase, never tokens, queues or participant payloads.
final class AccountScopeJournal implements AccountScopeStore {
  final File _file;
  AccountScopeJournal(Directory directory)
    : _file = File('${directory.path}/account-scope-pending.json');

  @override
  AccountScopeCheckpoint? readPending() {
    String content;
    try {
      content = _file.readAsStringSync();
    } on FileSystemException catch (error) {
      if (error.osError?.errorCode == 2) return null;
      rethrow;
    }
    if (content.isEmpty) throw const FormatException('Invalid privacy barrier');
    final String phase = content[0];
    // Legacy development checkpoints are conservatively unfinished closing.
    final bool legacy = phase == '{';
    if (!legacy && phase != 'O' && phase != 'C') {
      throw const FormatException('Invalid privacy phase');
    }
    final String encodedData;
    if (legacy) {
      encodedData = content;
    } else {
      encodedData = content.substring(1);
    }
    final Object? data = jsonDecode(encodedData);
    if (data is! Map ||
        data['version'] != 1 ||
        data['accountId'] is! String ||
        (data['accountId'] as String).trim().isEmpty) {
      throw const FormatException('Invalid privacy barrier');
    }
    return AccountScopeCheckpoint(
      accountId: data['accountId'] as String,
      closing: legacy || phase == 'C',
    );
  }

  @override
  void recordOpened(String accountId) {
    _file.parent.createSync(recursive: true);
    final File temporary = File('${_file.path}.tmp');
    temporary.writeAsStringSync(
      'O${jsonEncode({'version': 1, 'accountId': accountId})}',
      flush: true,
    );
    temporary.renameSync(_file.path);
  }

  @override
  void recordClosing(String accountId) {
    final AccountScopeCheckpoint? current = readPending();
    if (current == null || current.accountId != accountId) {
      throw const FormatException('Privacy checkpoint identity mismatch');
    }
    if (current.closing) return;
    // Change only the phase byte, retaining identity even if the process dies.
    // Seeking append-mode handles is supported by Dart IO on Android/Linux.
    final RandomAccessFile handle = _file.openSync(mode: FileMode.append);
    try {
      handle.setPositionSync(0);
      handle.writeByteSync(67); // C
      handle.flushSync();
    } finally {
      handle.closeSync();
    }
  }

  @override
  void finish() {
    try {
      _file.deleteSync();
    } on FileSystemException catch (error) {
      if (error.osError?.errorCode != 2) rethrow;
    }
  }
}
