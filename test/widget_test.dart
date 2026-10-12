// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ghost_vault/main.dart';
import 'package:ghost_vault/models/vault_item.dart';
import 'package:ghost_vault/services/vault_memory.dart';

void main() {
  testWidgets('GhostVault Desktop Smoke Test', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      VaultMemory().stopWatchdog();
    });

    await tester.pumpWidget(const GhostVaultApp());
    expect(find.byType(GhostVaultApp), findsOneWidget);
    VaultMemory().stopWatchdog();
  });

  test('VaultMemory In-Memory Storage & Shredding Test', () {
    final memory = VaultMemory();
    final dummyBytes = Uint8List.fromList([1, 2, 3, 4, 5]);

    final item = VaultItem(
      id: 'test_1',
      name: 'top_secret.txt',
      sizeBytes: 5,
      mimeType: 'text/plain',
      bytes: dummyBytes,
      uploadedAt: DateTime.now(),
    );

    memory.addItem(item);
    expect(memory.totalFiles, 1);
    expect(memory.totalMemoryBytes, 5);

    // Test shredding
    memory.panicWipe();
    expect(memory.totalFiles, 0);
    expect(memory.totalMemoryBytes, 0);
    expect(dummyBytes.every((b) => b == 0), isTrue); // Byte buffer overwritten with zeros!
  });
}
