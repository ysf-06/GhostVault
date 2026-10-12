import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:ghost_vault/services/vault_crypto.dart';

void main() {
  test('KDF matches reference test vector', () {
    final salt = "0102030405060708090a0b0c0d0e0f10";
    final pin = "849201";
    final keyBytes = VaultCrypto.deriveKey(pin, salt, iterations: 1000);
    final hex = keyBytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    expect(hex, equals("b52119ef75d446887d03127c0eaaf4656000e3273b3532e15ec0dbf61eb4f626"));
  });

  test('VaultCrypto encryption and decryption matches', () {
    final salt = VaultCrypto.generateSalt();
    final iv = VaultCrypto.generateIvHex();
    final pin = "849201";
    final originalText = "Top-Secret-Military-Grade-Payload-12345";
    final originalBytes = Uint8List.fromList(utf8.encode(originalText));

    final encrypted = VaultCrypto.encryptBytes(
      plainBytes: originalBytes,
      pin: pin,
      saltHex: salt,
      ivHex: iv,
    );

    expect(encrypted, isNot(equals(originalBytes)));

    final decrypted = VaultCrypto.decryptBytes(
      cipherBytes: encrypted,
      pin: pin,
      saltHex: salt,
      ivHex: iv,
    );

    expect(utf8.decode(decrypted), equals(originalText));
  });
}
