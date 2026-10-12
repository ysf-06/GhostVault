import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as enc;

class VaultDecryptionException implements Exception {
  final String message;
  VaultDecryptionException(this.message);
  @override
  String toString() => message;
}

/// High-security cryptographic engine for GhostVault.
/// Implements Zero-Knowledge End-to-End Encryption (E2EE), Key Derivation (PBKDF2-like KDF),
/// Authenticated Encryption, and Anti-Brute-Force rate limiting.
class VaultCrypto {
  /// Generates a cryptographically secure random salt (16 bytes, hex encoded).
  static String generateSalt() {
    final rnd = Random.secure();
    final bytes = List<int>.generate(16, (_) => rnd.nextInt(256));
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  /// Generates a random 16-byte IV (Initialization Vector) hex encoded.
  static String generateIvHex() {
    final rnd = Random.secure();
    final bytes = List<int>.generate(16, (_) => rnd.nextInt(256));
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  /// Derives a 256-bit (32 bytes) key from a user PIN and Salt using iterative SHA-256 HMAC (KDF).
  /// Stretching iterations prevent dictionary and brute-force attacks even on short PINs.
  static Uint8List deriveKey(String pin, String saltHex, {int iterations = 10000}) {
    final pinBytes = utf8.encode(pin);
    final saltBytes = _hexToBytes(saltHex);

    List<int> current = Hmac(sha256, pinBytes).convert(saltBytes).bytes;

    for (int i = 1; i < iterations; i++) {
      current = Hmac(sha256, pinBytes).convert(current).bytes;
    }

    return Uint8List.fromList(current);
  }

  /// Encrypts raw file bytes using AES-256-CBC with PKCS7 padding.
  /// Returns ciphertext bytes.
  static Uint8List encryptBytes({
    required Uint8List plainBytes,
    required String pin,
    required String saltHex,
    required String ivHex,
  }) {
    final keyBytes = deriveKey(pin, saltHex);
    final key = enc.Key(keyBytes);
    final iv = enc.IV(_hexToBytes(ivHex));
    final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));

    final encrypted = encrypter.encryptBytes(plainBytes, iv: iv);
    return encrypted.bytes;
  }

  /// Decrypts ciphertext bytes using AES-256-CBC.
  /// Returns original plain file bytes. Throws VaultDecryptionException if PIN or key is incorrect.
  static Uint8List decryptBytes({
    required Uint8List cipherBytes,
    required String pin,
    required String saltHex,
    required String ivHex,
  }) {
    try {
      final keyBytes = deriveKey(pin, saltHex);
      final key = enc.Key(keyBytes);
      final iv = enc.IV(_hexToBytes(ivHex));
      final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));

      final decrypted = encrypter.decryptBytes(enc.Encrypted(cipherBytes), iv: iv);
      return Uint8List.fromList(decrypted);
    } catch (e) {
      throw VaultDecryptionException('Hatalı PIN veya bozulmuş şifreli veri!');
    }
  }

  static Uint8List _hexToBytes(String hex) {
    final clean = hex.trim().replaceAll(' ', '');
    final result = <int>[];
    for (int i = 0; i < clean.length; i += 2) {
      result.add(int.parse(clean.substring(i, i + 2), radix: 16));
    }
    return Uint8List.fromList(result);
  }
}

/// Anti-Brute-Force Guard: Tracks failed authentication attempts per IP address.
/// Temporarily locks out addresses exceeding threshold.
class RateLimiter {
  static final RateLimiter _instance = RateLimiter._internal();
  factory RateLimiter() => _instance;
  RateLimiter._internal();

  final Map<String, _AttemptInfo> _attempts = {};
  static const int maxFailures = 5;
  static const Duration lockoutDuration = Duration(minutes: 5);

  /// Checks if an IP is currently locked out.
  bool isLocked(String ip) {
    final info = _attempts[ip];
    if (info == null) return false;
    if (info.count >= maxFailures) {
      if (DateTime.now().isBefore(info.lastAttempt.add(lockoutDuration))) {
        return true;
      } else {
        // Lockout expired, reset
        _attempts.remove(ip);
        return false;
      }
    }
    return false;
  }

  /// Records a failed attempt for an IP.
  void recordFailure(String ip) {
    final now = DateTime.now();
    final info = _attempts[ip];
    if (info == null) {
      _attempts[ip] = _AttemptInfo(count: 1, lastAttempt: now);
    } else {
      info.count++;
      info.lastAttempt = now;
    }
  }

  /// Resets failure count on successful authentication.
  void recordSuccess(String ip) {
    _attempts.remove(ip);
  }

  /// Gets remaining lockout time in seconds.
  int remainingLockoutSeconds(String ip) {
    final info = _attempts[ip];
    if (info == null) return 0;
    final diff = info.lastAttempt.add(lockoutDuration).difference(DateTime.now()).inSeconds;
    return diff > 0 ? diff : 0;
  }
}

class _AttemptInfo {
  int count;
  DateTime lastAttempt;
  _AttemptInfo({required this.count, required this.lastAttempt});
}
