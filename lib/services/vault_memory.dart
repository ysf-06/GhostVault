import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/vault_item.dart';

/// Manages ephemeral memory allocation, item storage, and shredding.
class VaultMemory extends ChangeNotifier {
  static final VaultMemory _instance = VaultMemory._internal();
  factory VaultMemory() => _instance;
  VaultMemory._internal() {
    _startExpiryWatchdog();
  }

  final Map<String, VaultItem> _items = {};
  Timer? _watchdogTimer;

  List<VaultItem> get items => _items.values.toList()
    ..sort((a, b) => b.uploadedAt.compareTo(a.uploadedAt));

  int get totalFiles => _items.length;

  int get totalMemoryBytes {
    return _items.values.fold(0, (sum, item) => sum + item.sizeBytes);
  }

  String get formattedMemoryUsage {
    final bytes = totalMemoryBytes;
    if (bytes < 1024) return '$bytes Bytes';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  /// Adds a new item to RAM.
  void addItem(VaultItem item) {
    _items[item.id] = item;
    notifyListeners();
  }

  /// Retrieves an item by ID.
  VaultItem? getItem(String id) {
    return _items[id];
  }

  /// Records a download; if maxDownloads reached, shreds the item immediately.
  void recordDownload(String id) {
    final item = _items[id];
    if (item == null) return;

    item.downloadCount++;
    if (item.isExpired) {
      shredItem(id);
    } else {
      notifyListeners();
    }
  }

  /// Cryptographically shreds and removes a single item from RAM.
  void shredItem(String id) {
    final item = _items.remove(id);
    if (item != null) {
      item.shred();
      notifyListeners();
    }
  }

  /// Emergency Panic Button: Immediately wipes all items from RAM.
  void panicWipe() {
    for (final item in _items.values) {
      item.shred();
    }
    _items.clear();
    notifyListeners();
  }

  /// Periodically checks and purges expired items.
  void _startExpiryWatchdog() {
    _watchdogTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      final expiredIds = _items.values
          .where((item) => item.isExpired)
          .map((item) => item.id)
          .toList();

      if (expiredIds.isNotEmpty) {
        for (final id in expiredIds) {
          shredItem(id);
        }
      }
    });
  }

  /// Stops the watchdog timer (useful for clean teardown or tests).
  void stopWatchdog() {
    _watchdogTimer?.cancel();
    _watchdogTimer = null;
  }

  @override
  void dispose() {
    stopWatchdog();
    panicWipe();
    super.dispose();
  }
}
