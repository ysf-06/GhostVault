import 'dart:typed_data';

/// In-Memory representation of an ephemeral vault item.
/// Stored strictly in RAM, NEVER written to disk.
class VaultItem {
  final String id;
  final String name;
  final int sizeBytes;
  final String mimeType;
  
  /// The actual raw (or E2EE encrypted) bytes stored exclusively in memory.
  Uint8List bytes;
  
  final DateTime uploadedAt;
  final String? senderInfo;
  
  int downloadCount;
  final int? maxDownloads; // If set (e.g. 1), auto-destructs after N downloads
  final DateTime? expiresAt;
  
  /// Cryptographic metadata (E2EE Zero-Knowledge)
  final bool isEncrypted;
  final String? iv;   // Hex IV for AES-256
  final String? salt; // Hex Salt for PBKDF2 Key Derivation

  VaultItem({
    required this.id,
    required this.name,
    required this.sizeBytes,
    required this.mimeType,
    required this.bytes,
    required this.uploadedAt,
    this.senderInfo,
    this.downloadCount = 0,
    this.maxDownloads,
    this.expiresAt,
    this.isEncrypted = false,
    this.iv,
    this.salt,
  });

  /// Cryptographically shreds the byte buffer in RAM by overwriting it with zeros.
  void shred() {
    try {
      bytes.fillRange(0, bytes.length, 0);
    } catch (_) {}
    bytes = Uint8List(0);
  }

  bool get isExpired {
    if (expiresAt != null && DateTime.now().isAfter(expiresAt!)) {
      return true;
    }
    if (maxDownloads != null && downloadCount >= maxDownloads!) {
      return true;
    }
    return false;
  }

  Map<String, dynamic> toMetadataJson() {
    return {
      'id': id,
      'name': name,
      'sizeBytes': sizeBytes,
      'mimeType': mimeType,
      'uploadedAt': uploadedAt.toIso8601String(),
      'senderInfo': senderInfo ?? 'Anonymous',
      'downloadCount': downloadCount,
      'maxDownloads': maxDownloads,
      'expiresAt': expiresAt?.toIso8601String(),
      'isEncrypted': isEncrypted,
      'iv': iv,
      'salt': salt,
    };
  }

  String get formattedSize {
    if (sizeBytes < 1024) return '$sizeBytes B';
    if (sizeBytes < 1024 * 1024) {
      return '${(sizeBytes / 1024).toStringAsFixed(1)} KB';
    }
    if (sizeBytes < 1024 * 1024 * 1024) {
      return '${(sizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(sizeBytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }
}
