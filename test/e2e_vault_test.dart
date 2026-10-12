import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:ghost_vault/services/vault_server.dart';
import 'package:ghost_vault/services/vault_crypto.dart';
import 'package:ghost_vault/models/vault_item.dart';

void main() {
  group('GhostVault End-to-End Server & Mobile Sync Tests', () {
    late VaultServer server;
    final client = HttpClient();
    const testPort = 7799;

    setUp(() async {
      server = VaultServer();
      await server.start(port: testPort);
    });

    tearDown(() async {
      await server.stop();
    });

    test('1. Status endpoint returns server metadata and correct PIN', () async {
      final req = await client.getUrl(Uri.parse('http://127.0.0.1:$testPort/api/status'));
      final res = await req.close();
      expect(res.statusCode, 200);
      final body = await res.transform(utf8.decoder).join();
      final json = jsonDecode(body);
      expect(json['running'], true);
      expect(json['pin'], server.pin);
      expect(json['totalFiles'], 0);
    });

    test('2. Files list endpoint starts empty and updates upon upload', () async {
      // 1. Initial check: empty
      final req1 = await client.getUrl(Uri.parse('http://127.0.0.1:$testPort/api/files'));
      final res1 = await req1.close();
      expect(res1.statusCode, 200);
      final list1 = jsonDecode(await res1.transform(utf8.decoder).join()) as List;
      expect(list1.isEmpty, true);

      // 2. Simulate Phone Upload
      final dummyData = utf8.encode('Hello from Android Phone! This is a test file.');
      final uploadReq = await client.postUrl(Uri.parse('http://127.0.0.1:$testPort/api/upload'));
      uploadReq.headers.set('x-filename', Uri.encodeComponent('test_phone_photo.jpg'));
      uploadReq.headers.set('x-mimetype', 'image/jpeg');
      uploadReq.headers.set('x-encrypted', '1');
      uploadReq.headers.set('x-client-device', 'Mobil Telefon (Xiaomi)');
      uploadReq.add(dummyData);
      final uploadRes = await uploadReq.close();
      expect(uploadRes.statusCode, 200);
      final uploadJson = jsonDecode(await uploadRes.transform(utf8.decoder).join());
      expect(uploadJson['success'], true);
      final fileId = uploadJson['id'];

      // 3. Verify file appears in /api/files (Fix for Phone Bug #1)
      final req2 = await client.getUrl(Uri.parse('http://127.0.0.1:$testPort/api/files'));
      final res2 = await req2.close();
      expect(res2.statusCode, 200);
      final list2 = jsonDecode(await res2.transform(utf8.decoder).join()) as List;
      expect(list2.length, 1);
      expect(list2.first['name'], 'test_phone_photo.jpg');
      expect(list2.first['senderInfo'], 'Mobil Telefon (Xiaomi)');
      expect(list2.first['isEncrypted'], true);

      // 4. Verify on-the-fly decryption download with PIN
      final dlReq = await client.getUrl(Uri.parse('http://127.0.0.1:$testPort/api/download/$fileId?pin=${server.pin}'));
      final dlRes = await dlReq.close();
      expect(dlRes.statusCode, 200);
      final downloadedBytes = await dlRes.fold<List<int>>([], (prev, elem) => prev..addAll(elem));
      expect(downloadedBytes, dummyData);

      // 5. Verify download with WRONG PIN is rejected (Forbidden)
      final wrongReq = await client.getUrl(Uri.parse('http://127.0.0.1:$testPort/api/download/$fileId?pin=000000'));
      final wrongRes = await wrongReq.close();
      expect(wrongRes.statusCode, 403);
    });

    test('3. File uploaded on PC can be downloaded and decrypted by Phone with PIN', () async {
      // Simulate PC adding file directly to VaultMemory with AES encryption
      final pcFileBytes = utf8.encode('@echo off\necho GhostVault Build Script\npause');
      final ivHex = VaultCrypto.generateIvHex();
      final encryptedBytes = VaultCrypto.encryptBytes(
        plainBytes: Uint8List.fromList(pcFileBytes),
        pin: server.pin,
        saltHex: server.saltHex,
        ivHex: ivHex,
      );

      final item = VaultItem(
        id: 'pc_item_1',
        name: 'build.bat',
        sizeBytes: encryptedBytes.length,
        mimeType: 'application/x-bat',
        bytes: encryptedBytes,
        uploadedAt: DateTime.now(),
        isEncrypted: true,
        iv: ivHex,
        salt: server.saltHex,
        senderInfo: 'Bu Bilgisayar',
      );
      server.memory.addItem(item);

      // Verify it appears in /api/files
      final req = await client.getUrl(Uri.parse('http://127.0.0.1:$testPort/api/files'));
      final res = await req.close();
      expect(res.statusCode, 200);
      final list = jsonDecode(await res.transform(utf8.decoder).join()) as List;
      expect(list.any((f) => f['name'] == 'build.bat'), true);

      // Verify Phone downloading with PIN receives clean decrypted build.bat
      final dlReq = await client.getUrl(Uri.parse('http://127.0.0.1:$testPort/api/download/pc_item_1?pin=${server.pin}'));
      final dlRes = await dlReq.close();
      expect(dlRes.statusCode, 200);
      final dlBytes = await dlRes.fold<List<int>>([], (prev, elem) => prev..addAll(elem));
      expect(utf8.decode(dlBytes), '@echo off\necho GhostVault Build Script\npause');
    });
  });
}
