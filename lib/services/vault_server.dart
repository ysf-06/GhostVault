import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';
import '../models/vault_item.dart';
import '../web/embedded_client.dart';
import 'tunnel_service.dart';
import 'vault_crypto.dart';
import 'vault_memory.dart';

class NetworkCandidate {
  final String name;
  final String ip;
  final bool isVirtual;
  final int score;

  NetworkCandidate({
    required this.name,
    required this.ip,
    required this.isVirtual,
    required this.score,
  });
}

/// The In-Memory Ephemeral HTTP Server hosting the GhostVault single-page web app and API.
class VaultServer extends ChangeNotifier {
  static final VaultServer _instance = VaultServer._internal();
  factory VaultServer() => _instance;
  VaultServer._internal() {
    regeneratePin();
  }

  HttpServer? _server;
  int _port = 7788;
  String _pin = '';
  String _saltHex = '';
  bool _isRunning = false;
  String _localIp = '127.0.0.1';
  List<NetworkCandidate> _interfaces = [];

  final VaultMemory memory = VaultMemory();
  final TunnelService tunnelService = TunnelService();
  final RateLimiter rateLimiter = RateLimiter();

  bool get isRunning => _isRunning;
  int get port => _port;
  String get pin => _pin;
  String get saltHex => _saltHex;
  String get localIp => _localIp;
  List<NetworkCandidate> get interfaces => _interfaces;

  /// Returns the direct LAN URL
  String get accessUrl => 'http://$_localIp:$_port';

  /// Returns the mDNS / Bonjour URL for Macs and iPhones
  String get mdnsUrl => 'http://${Platform.localHostname.toLowerCase()}.local:$_port';

  /// Returns effective public or tunnel access URL if tunnel is running, otherwise LAN URL
  String get effectiveUrl => tunnelService.isTunnelActive ? (tunnelService.tunnelUrl ?? accessUrl) : accessUrl;

  /// Generates a fresh random PIN and cryptographic session Salt
  void regeneratePin() {
    final rnd = Random.secure();
    _pin = (100000 + rnd.nextInt(900000)).toString();
    _saltHex = VaultCrypto.generateSalt();
    notifyListeners();
  }

  /// Sets chosen local IP manually from UI
  void setLocalIp(String ip) {
    _localIp = ip;
    notifyListeners();
  }

  /// Re-detects interfaces on the fly
  Future<void> refreshInterfaces() async {
    await _detectLocalIp();
    notifyListeners();
  }

  /// Starts the embedded HTTP server on all IPv4 interfaces.
  Future<void> start({int port = 7788}) async {
    if (_isRunning) return;
    _port = port;
    regeneratePin();
    await _detectLocalIp();

    final router = Router();

    // Serve Embedded Single-Page App with zero disk access
    router.get('/', (Request req) {
      return Response.ok(
        EmbeddedWebClient.html,
        headers: {
          'content-type': 'text/html; charset=utf-8',
          'cache-control': 'no-cache, no-store, must-revalidate',
        },
      );
    });

    // Vault Status & Handshake
    router.get('/api/status', (Request req) {
      final clientIp = _extractClientIp(req);
      if (rateLimiter.isLocked(clientIp)) {
        return Response(429,
            body: jsonEncode({
              'error': 'Too many failed attempts. Locked out for 5 minutes.',
              'remaining': rateLimiter.remainingLockoutSeconds(clientIp)
            }),
            headers: {'content-type': 'application/json'});
      }

      final clientPin = req.headers['x-vault-pin'] ?? req.headers['x-pin'] ?? req.url.queryParameters['pin'];
      final isAuthenticated = clientPin != null && clientPin == _pin;

      return Response.ok(
        jsonEncode({
          'running': _isRunning,
          'authenticated': isAuthenticated,
          'salt': _saltHex,
          'totalFiles': memory.totalFiles,
          'memoryUsage': memory.formattedMemoryUsage,
          'localIp': _localIp,
          'port': _port,
          'hostname': Platform.localHostname,
          'mdnsUrl': mdnsUrl,
          'tunnelActive': tunnelService.isTunnelActive,
          'tunnelUrl': tunnelService.tunnelUrl,
          'interfaces': _interfaces.map((i) => {'name': i.name, 'ip': i.ip}).toList(),
        }),
        headers: {'content-type': 'application/json'},
      );
    });

    // Active Files (Metadata only - Requires Authentication)
    router.get('/api/files', (Request req) {
      final clientIp = _extractClientIp(req);
      if (rateLimiter.isLocked(clientIp)) {
        return Response(429,
            body: jsonEncode({
              'error': 'Too many failed attempts. Locked out for 5 minutes.',
              'remaining': rateLimiter.remainingLockoutSeconds(clientIp)
            }),
            headers: {'content-type': 'application/json'});
      }
      if (!_isAuthorized(req, clientIp)) {
        return Response(401,
            body: jsonEncode({'error': 'Unauthorized: Valid PIN required'}),
            headers: {'content-type': 'application/json'});
      }
      final list = memory.items.map((i) => i.toMetadataJson()).toList();
      return Response.ok(
        jsonEncode(list),
        headers: {'content-type': 'application/json'},
      );
    });

    // Upload Handler (Stores bytes in RAM - Requires Authentication & Size Limit)
    router.post('/api/upload', (Request req) async {
      try {
        final clientIp = _extractClientIp(req);
        if (rateLimiter.isLocked(clientIp)) {
          return Response(429,
              body: jsonEncode({'error': 'Rate limit exceeded. Locked out for 5 minutes.'}),
              headers: {'content-type': 'application/json'});
        }
        if (!_isAuthorized(req, clientIp)) {
          return Response(401,
              body: jsonEncode({'error': 'Unauthorized: Valid PIN required'}),
              headers: {'content-type': 'application/json'});
        }

        const maxUploadBytes = 500 * 1024 * 1024; // 500 MB RAM protection limit
        final contentLength = req.contentLength;
        if (contentLength != null && contentLength > maxUploadBytes) {
          return Response(413,
              body: jsonEncode({'error': 'Payload Too Large: Maximum upload size is 500MB'}),
              headers: {'content-type': 'application/json'});
        }

        final rawFilename = req.headers['x-filename'] ?? 'secret_file.bin';
        final fileName = Uri.decodeComponent(rawFilename);
        final mimeType = req.headers['x-mimetype'] ?? 'application/octet-stream';
        var iv = req.headers['x-iv'];
        final salt = req.headers['x-salt'] ?? _saltHex;
        final isBurn = req.headers['x-burn'] == '1';
        final isEncrypted = req.headers['x-encrypted'] == '1';

        final bytesBuilder = BytesBuilder(copy: false);
        var totalBytesRead = 0;
        await for (final chunk in req.read()) {
          totalBytesRead += chunk.length;
          if (totalBytesRead > maxUploadBytes) {
            return Response(413,
                body: jsonEncode({'error': 'Payload Too Large: Stream exceeded 500MB limit'}),
                headers: {'content-type': 'application/json'});
          }
          bytesBuilder.add(chunk);
        }
        var bytes = bytesBuilder.toBytes();

        // If client requested encryption into RAM and didn't pre-encrypt
        if (isEncrypted && (iv == null || iv.isEmpty)) {
          iv = VaultCrypto.generateIvHex();
          bytes = VaultCrypto.encryptBytes(
            plainBytes: bytes,
            pin: _pin,
            saltHex: salt,
            ivHex: iv,
          );
        }

        final item = VaultItem(
          id: '${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(9999)}',
          name: fileName,
          sizeBytes: bytes.length,
          mimeType: mimeType,
          bytes: bytes,
          uploadedAt: DateTime.now(),
          maxDownloads: isBurn ? 1 : null,
          isEncrypted: isEncrypted,
          iv: iv,
          salt: salt,
          senderInfo: req.headers['x-client-device'] ?? 'Telefon / Web',
        );

        memory.addItem(item);

        return Response.ok(
          jsonEncode({'success': true, 'id': item.id}),
          headers: {'content-type': 'application/json'},
        );
      } catch (e) {
        return Response.internalServerError(body: 'Upload failed: $e');
      }
    });

    // Download Handler (Serves directly from RAM, auto-destructs if burn-after-reading - Requires Authentication)
    router.get('/api/download/<id>', (Request req, String id) {
      final clientIp = _extractClientIp(req);
      if (rateLimiter.isLocked(clientIp)) {
        return Response(429,
            body: 'Rate limit exceeded. Locked out for 5 minutes.',
            headers: {'content-type': 'text/plain; charset=utf-8'});
      }

      if (!_isAuthorized(req, clientIp)) {
        return Response(401,
            body: 'Gecersiz veya eksik PIN! Dosya indirilemez.',
            headers: {'content-type': 'text/plain; charset=utf-8'});
      }

      final item = memory.getItem(id);
      if (item == null) {
        return Response.notFound("Dosya bulunamadi veya RAM'den imha edildi");
      }

      Uint8List outputBytes = item.bytes;

      // Decrypt on the fly if client provides correct PIN and item was encrypted
      if (item.isEncrypted) {
        try {
          outputBytes = VaultCrypto.decryptBytes(
            cipherBytes: item.bytes,
            pin: _pin,
            saltHex: item.salt ?? _saltHex,
            ivHex: item.iv ?? VaultCrypto.generateIvHex(),
          );
        } catch (_) {
          return Response.internalServerError(body: 'Sifre cozme hatasi');
        }
      }

      final copy = Uint8List.fromList(outputBytes);

      // Record download (triggers auto-shred if maxDownloads reached)
      memory.recordDownload(id);

      return Response.ok(
        copy,
        headers: {
          'content-type': item.mimeType,
          'content-disposition': 'attachment; filename="${Uri.encodeComponent(item.name)}"',
          'x-iv': item.iv ?? '',
          'x-salt': item.salt ?? _saltHex,
          'x-encrypted': item.isEncrypted ? '1' : '0',
          'cache-control': 'no-cache, no-store',
        },
      );
    });

    // Delete Item (Requires Authentication)
    router.delete('/api/files/<id>', (Request req, String id) {
      final clientIp = _extractClientIp(req);
      if (rateLimiter.isLocked(clientIp)) {
        return Response(429, body: jsonEncode({'error': 'Rate limit exceeded'}), headers: {'content-type': 'application/json'});
      }
      if (!_isAuthorized(req, clientIp)) {
        return Response(401, body: jsonEncode({'error': 'Unauthorized: Valid PIN required'}), headers: {'content-type': 'application/json'});
      }
      memory.shredItem(id);
      return Response.ok(jsonEncode({'success': true}), headers: {'content-type': 'application/json'});
    });

    // Emergency Panic Purge (Requires Authentication)
    router.post('/api/panic', (Request req) {
      final clientIp = _extractClientIp(req);
      if (rateLimiter.isLocked(clientIp)) {
        return Response(429, body: jsonEncode({'error': 'Rate limit exceeded'}), headers: {'content-type': 'application/json'});
      }
      if (!_isAuthorized(req, clientIp)) {
        return Response(401, body: jsonEncode({'error': 'Unauthorized: Valid PIN required'}), headers: {'content-type': 'application/json'});
      }
      memory.panicWipe();
      return Response.ok(jsonEncode({'success': true, 'message': 'All memory purged'}), headers: {'content-type': 'application/json'});
    });

    // CORS & Preflight OPTIONS Handler
    Middleware corsHeadersMiddleware() {
      const headers = {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'GET, POST, DELETE, OPTIONS',
        'Access-Control-Allow-Headers': 'Origin, Content-Type, Accept, X-Filename, X-MimeType, X-IV, X-Salt, X-Burn, X-Encrypted, X-Client-Device, X-Pin, X-Vault-PIN',
        'Access-Control-Expose-Headers': 'X-IV, X-Salt, X-Encrypted, Content-Disposition',
      };

      Response? handleOptions(Request request) {
        if (request.method == 'OPTIONS') {
          return Response.ok('', headers: headers);
        }
        return null;
      }

      Response addHeaders(Response response) => response.change(headers: headers);

      return createMiddleware(
        requestHandler: handleOptions,
        responseHandler: addHeaders,
      );
    }

    final handler = const Pipeline()
        .addMiddleware(corsHeadersMiddleware())
        .addHandler(router.call);

    try {
      _server = await shelf_io.serve(handler, InternetAddress.anyIPv4, _port);
      _isRunning = true;
      notifyListeners();
    } catch (e) {
      _port = _port + 1;
      _server = await shelf_io.serve(handler, InternetAddress.anyIPv4, _port);
      _isRunning = true;
      notifyListeners();
    }
  }

    bool _isAuthorized(Request req, String clientIp) {
    final clientPin = req.headers['x-vault-pin'] ?? req.headers['x-pin'] ?? req.url.queryParameters['pin'];
    if (clientPin == null || clientPin.isEmpty) {
      rateLimiter.recordFailure(clientIp);
      return false;
    }
    if (clientPin == _pin) {
      rateLimiter.recordSuccess(clientIp);
      return true;
    }
    rateLimiter.recordFailure(clientIp);
    return false;
  }

  String _extractClientIp(Request req) {
    final forwarded = req.headers['x-forwarded-for'];
    if (forwarded != null && forwarded.isNotEmpty) {
      return forwarded.split(',').first.trim();
    }
    final connectionInfo = req.context['shelf.io.connection_info'] as HttpConnectionInfo?;
    return connectionInfo?.remoteAddress.address ?? 'unknown';
  }

  /// Stops server, terminates active tunnels, and securely shreds all RAM.
  Future<void> stop() async {
    await tunnelService.stopTunnel();
    memory.panicWipe();
    await _server?.close(force: true);
    _server = null;
    _isRunning = false;
    notifyListeners();
  }

  /// Intelligently finds physical Wi-Fi/Ethernet IPv4 addresses and filters virtual adapters.
  Future<void> _detectLocalIp() async {
    try {
      final interfaces = await NetworkInterface.list(
        includeLoopback: false,
        type: InternetAddressType.IPv4,
      );

      final candidates = <NetworkCandidate>[];

      for (final iface in interfaces) {
        final nameLower = iface.name.toLowerCase();
        final isVirtual = nameLower.contains('vmware') ||
            nameLower.contains('virtual') ||
            nameLower.contains('vbox') ||
            nameLower.contains('host-only') ||
            nameLower.contains('bluetooth') ||
            nameLower.contains('pdanet') ||
            nameLower.contains('loopback') ||
            nameLower.contains('wsl') ||
            nameLower.contains('hyper-v') ||
            nameLower.contains('teredo') ||
            nameLower.contains('pseudo') ||
            nameLower.contains('vethernet');

        for (final addr in iface.addresses) {
          if (addr.isLoopback) continue;
          final ip = addr.address;
          if (ip.startsWith('127.') || ip.startsWith('169.254.')) continue;
          if (ip.startsWith('192.168.56.')) continue; // VirtualBox default subnet

          int score = 0;
          if (nameLower.contains('wi-fi') || nameLower.contains('wifi') || nameLower.contains('wlan') || nameLower.contains('kablosuz')) {
            score += 100;
          } else if (nameLower.contains('ethernet') && !isVirtual) {
            score += 70;
          }

          if (!isVirtual) score += 30;

          candidates.add(NetworkCandidate(
            name: iface.name,
            ip: ip,
            isVirtual: isVirtual,
            score: score,
          ));
        }
      }

      candidates.sort((a, b) => b.score.compareTo(a.score));
      _interfaces = candidates;

      if (candidates.isNotEmpty) {
        final exists = candidates.any((c) => c.ip == _localIp);
        if (!exists || _localIp == '127.0.0.1' || _localIp == '192.168.56.1') {
          _localIp = candidates.first.ip;
        }
      } else {
        _localIp = '127.0.0.1';
      }
    } catch (_) {
      _localIp = '127.0.0.1';
    }
  }
}
