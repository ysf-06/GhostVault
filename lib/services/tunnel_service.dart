import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';

/// Ultra-Reliable Zero-Port-Forwarding Encrypted Tunnel Service.
/// Prioritizes bundled Cloudflare Quick Tunnel (trycloudflare.com) for 100% uptime,
/// zero-configuration, and global high-speed edge delivery.
/// Falls back to OpenSSH (localhost.run) if cloudflared is unavailable.
class TunnelService extends ChangeNotifier {
  static final TunnelService _instance = TunnelService._internal();
  factory TunnelService() => _instance;
  TunnelService._internal();

  Process? _tunnelProcess;
  bool _isTunnelActive = false;
  bool _isStarting = false;
  String? _tunnelUrl;
  String? _statusMessage;

  bool get isTunnelActive => _isTunnelActive;
  bool get isStarting => _isStarting;
  String? get tunnelUrl => _tunnelUrl;
  String? get statusMessage => _statusMessage;

  String? _findCloudflaredBinary() {
    final exeDir = File(Platform.resolvedExecutable).parent.path;
    final candidates = [
      '$exeDir\\cloudflared.exe',
      'C:\\Users\\yusuf\\AppData\\Local\\Programs\\GhostVault\\cloudflared.exe',
      'C:\\C_Projects\\GhostVault\\windows\\cloudflared.exe',
      'cloudflared.exe',
    ];

    for (final c in candidates) {
      if (File(c).existsSync()) {
        return c;
      }
    }
    return null;
  }

  /// Starts the zero-configuration encrypted tunnel on the specified local port.
  Future<bool> startTunnel(int localPort) async {
    if (_isTunnelActive || _isStarting) return true;

    _isStarting = true;
    _statusMessage = 'Cloudflare Güvenli Tüneli kuruluyor...';
    notifyListeners();

    final cfBinary = _findCloudflaredBinary();

    if (cfBinary != null) {
      return await _startCloudflaredTunnel(cfBinary, localPort);
    } else {
      return await _startSshTunnel(localPort);
    }
  }

  Future<bool> _startCloudflaredTunnel(String binaryPath, int localPort) async {
    try {
      final process = await Process.start(
        binaryPath,
        ['tunnel', '--url', 'http://127.0.0.1:$localPort'],
        mode: ProcessStartMode.normal,
      );

      _tunnelProcess = process;
      final completer = Completer<bool>();
      final cfRegex = RegExp(r'https://[a-zA-Z0-9-]+\.trycloudflare\.com');

      void handleLine(String line) {
        if (!completer.isCompleted) {
          final match = cfRegex.firstMatch(line);
          if (match != null) {
            _tunnelUrl = match.group(0);
            _isTunnelActive = true;
            _isStarting = false;
            _statusMessage = 'Cloudflare Tüneli Aktif (Uçtan Uca HTTPS)';
            notifyListeners();
            completer.complete(true);
          }
        }
      }

      process.stdout.transform(utf8.decoder).transform(const LineSplitter()).listen(handleLine);
      process.stderr.transform(utf8.decoder).transform(const LineSplitter()).listen(handleLine);

      process.exitCode.then((exitCode) {
        _isTunnelActive = false;
        _isStarting = false;
        _tunnelUrl = null;
        _tunnelProcess = null;
        _statusMessage = 'Tünel Kapandı';
        notifyListeners();
        if (!completer.isCompleted) {
          completer.complete(false);
        }
      });

      // Timeout after 20 seconds
      Future.delayed(const Duration(seconds: 20), () {
        if (!completer.isCompleted) {
          _isStarting = false;
          _statusMessage = 'Cloudflare bağlantı zaman aşımı';
          notifyListeners();
          completer.complete(false);
        }
      });

      return await completer.future;
    } catch (e) {
      _isStarting = false;
      _statusMessage = 'Cloudflare başlatılamadı: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> _startSshTunnel(int localPort) async {
    try {
      final process = await Process.start(
        'ssh',
        [
          '-o', 'StrictHostKeyChecking=no',
          '-o', 'ServerAliveInterval=30',
          '-R', '80:127.0.0.1:$localPort',
          'nokey@localhost.run',
        ],
        mode: ProcessStartMode.normal,
      );

      _tunnelProcess = process;
      final completer = Completer<bool>();
      final urlRegex = RegExp(r'https://[a-zA-Z0-9.-]+\.lhr\.life');

      process.stdout.transform(utf8.decoder).transform(const LineSplitter()).listen((line) {
        if (!completer.isCompleted) {
          final match = urlRegex.firstMatch(line);
          if (match != null) {
            _tunnelUrl = match.group(0);
            _isTunnelActive = true;
            _isStarting = false;
            _statusMessage = 'Tünel Aktif (localhost.run)';
            notifyListeners();
            completer.complete(true);
          }
        }
      });

      process.exitCode.then((_) {
        _isTunnelActive = false;
        _isStarting = false;
        _tunnelUrl = null;
        _tunnelProcess = null;
        notifyListeners();
        if (!completer.isCompleted) completer.complete(false);
      });

      return await completer.future;
    } catch (e) {
      _isStarting = false;
      _statusMessage = 'Tünel başlatılamadı: $e';
      notifyListeners();
      return false;
    }
  }

  /// Stops the tunnel immediately.
  Future<void> stopTunnel() async {
    if (_tunnelProcess != null) {
      _tunnelProcess!.kill();
      _tunnelProcess = null;
    }
    _isTunnelActive = false;
    _isStarting = false;
    _tunnelUrl = null;
    _statusMessage = 'Tünel devre dışı';
    notifyListeners();
  }

  @override
  void dispose() {
    stopTunnel();
    super.dispose();
  }
}
