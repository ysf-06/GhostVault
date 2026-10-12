import 'dart:typed_data';
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'models/vault_item.dart';
import 'services/vault_crypto.dart';
import 'services/vault_memory.dart';
import 'services/vault_server.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final server = VaultServer();
  await server.start();

  runApp(const GhostVaultApp());
}

class GhostVaultApp extends StatelessWidget {
  const GhostVaultApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GhostVault - Ephemeral Safe',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF060911),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF00F0FF),
          secondary: Color(0xFF00FF9D),
          error: Color(0xFFFF3366),
          surface: Color(0xFF10172A),
        ),
        cardTheme: CardThemeData(
          color: const Color(0xFF10172A).withValues(alpha: 0.85),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(color: const Color(0xFF00F0FF).withValues(alpha: 0.2)),
          ),
        ),
      ),
      home: const VaultDashboardScreen(),
    );
  }
}

class VaultDashboardScreen extends StatefulWidget {
  const VaultDashboardScreen({super.key});

  @override
  State<VaultDashboardScreen> createState() => _VaultDashboardScreenState();
}

class _VaultDashboardScreenState extends State<VaultDashboardScreen> {
  final VaultServer server = VaultServer();
  final VaultMemory memory = VaultMemory();

  int _selectedTab = 0; // 0: Kasa Sunucum, 1: Uzak Kasaya Bağlan
  bool _useTunnelQr = false;

  // Remote Vault Client State (P2P Desktop Bridge)
  final TextEditingController _remoteHostController = TextEditingController(text: '192.168.1.');
  final TextEditingController _remotePinController = TextEditingController();
  bool _isConnectingRemote = false;
  bool _isConnectedRemote = false;
  String? _remoteError;
  Map<String, dynamic>? _remoteStatus;
  List<Map<String, dynamic>> _remoteFiles = [];
  Timer? _remotePollTimer;

  @override
  void initState() {
    super.initState();
    server.addListener(_onUpdate);
    memory.addListener(_onUpdate);
    server.tunnelService.addListener(_onUpdate);
  }

  @override
  void dispose() {
    _remotePollTimer?.cancel();
    server.removeListener(_onUpdate);
    memory.removeListener(_onUpdate);
    server.tunnelService.removeListener(_onUpdate);
    _remoteHostController.dispose();
    _remotePinController.dispose();
    super.dispose();
  }

  void _onUpdate() {
    if (mounted) setState(() {});
  }

  ({IconData icon, Color color, String badge}) _getFileMeta(String fileName, String mimeType) {
    final ext = fileName.contains('.') ? fileName.split('.').last.toLowerCase() : '';
    if (['apk', 'xapk', 'aab'].contains(ext)) {
      return (icon: Icons.android_rounded, color: const Color(0xFF00FF9D), badge: 'UYGULAMA (APK)');
    } else if (['exe', 'msi', 'bat', 'cmd'].contains(ext)) {
      return (icon: Icons.laptop_windows_rounded, color: const Color(0xFF00F0FF), badge: 'PROGRAM (EXE)');
    } else if (['dmg', 'pkg', 'app'].contains(ext)) {
      return (icon: Icons.apple_rounded, color: const Color(0xFFC084FC), badge: 'MAC UYGULAMASI');
    } else if (['mp4', 'mkv', 'avi', 'mov', 'webm', 'wmv'].contains(ext) || mimeType.startsWith('video/')) {
      return (icon: Icons.movie_creation_rounded, color: const Color(0xFF00F0FF), badge: 'VİDEO');
    } else if (['jpg', 'jpeg', 'png', 'gif', 'webp', 'svg'].contains(ext) || mimeType.startsWith('image/')) {
      return (icon: Icons.image_rounded, color: const Color(0xFF00FF9D), badge: 'RESİM');
    } else if (['mp3', 'wav', 'ogg', 'm4a', 'flac'].contains(ext) || mimeType.startsWith('audio/')) {
      return (icon: Icons.music_note_rounded, color: const Color(0xFFFF9900), badge: 'SES / MÜZİK');
    } else if (['zip', 'rar', '7z', 'tar', 'gz'].contains(ext)) {
      return (icon: Icons.archive_rounded, color: const Color(0xFFFFB800), badge: 'ARŞİV');
    } else if (fileName.endsWith('.txt')) {
      return (icon: Icons.lock_clock_rounded, color: const Color(0xFFC084FC), badge: 'GİZLİ NOT');
    }
    return (icon: Icons.insert_drive_file_rounded, color: const Color(0xFF8B949E), badge: 'BELGE');
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✓ $label panoya kopyalandı!'),
        backgroundColor: const Color(0xFF00FF9D).withValues(alpha: 0.9),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _pickAndAddFile() async {
    try {
      final files = await FilePicker.pickFiles();

      if (files.isNotEmpty) {
        int addedCount = 0;
        final totalSelected = files.length;

        for (int i = 0; i < totalSelected; i++) {
          final file = files[i];
          final rawBytes = await file.xFile.readAsBytes();
          if (rawBytes.isEmpty) continue;

          final salt = server.saltHex;
          final iv = VaultCrypto.generateIvHex();

          // Zero-Knowledge Encrypt in RAM
          final encryptedBytes = VaultCrypto.encryptBytes(
            plainBytes: rawBytes,
            pin: server.pin,
            saltHex: salt,
            ivHex: iv,
          );

          final item = VaultItem(
            id: '${DateTime.now().millisecondsSinceEpoch}_${i}_local',
            name: file.name,
            sizeBytes: encryptedBytes.length,
            mimeType: 'application/octet-stream',
            bytes: encryptedBytes,
            uploadedAt: DateTime.now(),
            senderInfo: 'Bu Bilgisayar (E2EE)',
            isEncrypted: true,
            iv: iv,
            salt: salt,
          );

          memory.addItem(item);
          addedCount++;
        }

        if (mounted && addedCount > 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                addedCount == 1
                    ? '✓ "${files.first.name}" E2EE ile şifrelendi ve RAM\'e eklendi!'
                    : '✓ $addedCount dosya grup halinde E2EE ile şifrelendi ve RAM\'e eklendi!',
              ),
              backgroundColor: const Color(0xFF00F0FF).withValues(alpha: 0.9),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Dosya eklenemedi: $e'),
            backgroundColor: const Color(0xFFFF3366),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _saveFileToDisk(VaultItem item) async {
    try {
      Uint8List outputBytes = item.bytes;

      // If file is encrypted with E2EE, decrypt it with current Vault PIN & Salt!
      if (item.isEncrypted) {
        try {
          outputBytes = VaultCrypto.decryptBytes(
            cipherBytes: item.bytes,
            pin: server.pin,
            saltHex: item.salt ?? server.saltHex,
            ivHex: item.iv ?? VaultCrypto.generateIvHex(),
          );
        } catch (decErr) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('❌ Şifre Çözülemedi: PIN uyuşmuyor! ($decErr)'),
                backgroundColor: const Color(0xFFFF3366),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
          return;
        }
      }

      final savedUri = await FilePicker.saveFile(
        dialogTitle: 'Dosyayı Diske Çıkar',
        fileName: item.name,
        bytes: outputBytes,
      );

      if (savedUri != null) {
        memory.recordDownload(item.id);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✓ "${item.name}" çözüldü ve diske kaydedildi!'),
              backgroundColor: const Color(0xFF00FF9D).withValues(alpha: 0.9),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Kayıt hatası: $e'),
            backgroundColor: const Color(0xFFFF3366),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showAddNoteDialog() {
    final noteController = TextEditingController();
    bool burnAfterReading = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF10172A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: Color(0xFF00F0FF), width: 1.2),
          ),
          title: const Row(
            children: [
              Icon(Icons.shield_rounded, color: Color(0xFF00F0FF)),
              SizedBox(width: 8),
              Text('Gizli E2EE Not Ekle', style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: noteController,
                maxLines: 4,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Şifrelenecek gizli mesaj, parola veya not...',
                  hintStyle: const TextStyle(color: Color(0xFF8B949E)),
                  filled: true,
                  fillColor: const Color(0xFF080B11),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: const Color(0xFF00F0FF).withValues(alpha: 0.3)),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('🔥 Tek Okumada İmha Et (Self-Destruct)', style: TextStyle(fontSize: 13)),
                value: burnAfterReading,
                activeColor: const Color(0xFFFF3366),
                onChanged: (val) => setDialogState(() => burnAfterReading = val ?? false),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('İptal', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00F0FF),
                foregroundColor: Colors.black,
              ),
              onPressed: () {
                final text = noteController.text.trim();
                if (text.isNotEmpty) {
                  final rawBytes = Uint8List.fromList(utf8.encode(text));
                  final salt = server.saltHex;
                  final iv = VaultCrypto.generateIvHex();

                  final encrypted = VaultCrypto.encryptBytes(
                    plainBytes: rawBytes,
                    pin: server.pin,
                    saltHex: salt,
                    ivHex: iv,
                  );

                  final item = VaultItem(
                    id: '${DateTime.now().millisecondsSinceEpoch}_note',
                    name: 'gizli_not_${DateTime.now().second}.txt',
                    sizeBytes: encrypted.length,
                    mimeType: 'text/plain; charset=utf-8',
                    bytes: encrypted,
                    uploadedAt: DateTime.now(),
                    senderInfo: 'Masaüstü (E2EE Not)',
                    maxDownloads: burnAfterReading ? 1 : null,
                    isEncrypted: true,
                    iv: iv,
                    salt: salt,
                  );
                  memory.addItem(item);
                  Navigator.pop(ctx);
                }
              },
              child: const Text('Şifrele ve Ekle', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _showAdapterPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF10172A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.hub_rounded, color: Color(0xFF00F0FF)),
                  SizedBox(width: 8),
                  Text('Ağ Arayüzü Seçici (Bağımsız Mod)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Dosya paylaşımı yapılacak yerel ağ kartını (Wi-Fi, Ethernet, Hotspot) seçin:',
                style: TextStyle(fontSize: 13, color: Color(0xFF8B949E)),
              ),
              const SizedBox(height: 16),
              ...server.interfaces.map((iface) {
                final isSelected = iface.ip == server.localIp;
                final isWifi = iface.name.toLowerCase().contains('wi-fi') || iface.name.toLowerCase().contains('wlan');
                final isHotspot = iface.ip.startsWith('192.168.137.') || iface.name.toLowerCase().contains('hotspot');

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF00F0FF).withValues(alpha: 0.15) : const Color(0xFF080B11),
                    borderRadius: BorderRadius.circular(12),
                    border: Border(
                      left: BorderSide(
                        color: isSelected ? const Color(0xFF00F0FF) : Colors.transparent,
                        width: 4,
                      ),
                    ),
                  ),
                  child: ListTile(
                    leading: Icon(
                      isHotspot ? Icons.wifi_tethering_rounded : (isWifi ? Icons.wifi : Icons.settings_ethernet),
                      color: isSelected ? const Color(0xFF00F0FF) : Colors.white70,
                    ),
                    title: Text(iface.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    subtitle: Text('${iface.ip} ${isHotspot ? "(Hava Boşluğu / Hotspot)" : ""}', style: const TextStyle(fontSize: 12, color: Color(0xFF8B949E))),
                    trailing: isSelected ? const Icon(Icons.check_circle_rounded, color: Color(0xFF00FF9D)) : null,
                    onTap: () {
                      server.setLocalIp(iface.ip);
                      Navigator.pop(ctx);
                    },
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  // --- REMOTE VAULT P2P METHODS ---
  Future<void> _connectToRemoteVault() async {
    final host = _remoteHostController.text.trim();
    // pin is used during file operations

    if (host.isEmpty) {
      setState(() => _remoteError = 'Lütfen bir IP, mDNS (.local) veya Tünel adresi girin!');
      return;
    }

    setState(() {
      _isConnectingRemote = true;
      _remoteError = null;
    });

    try {
      final cleanUrl = host.startsWith('http') ? host : 'http://$host';
      final uri = Uri.parse('$cleanUrl/api/status');

      final client = HttpClient()..connectionTimeout = const Duration(seconds: 5);
      final request = await client.getUrl(uri);
      final pin = _remotePinController.text.trim();
      if (pin.isNotEmpty) {
        request.headers.set('X-Vault-PIN', pin);
        request.headers.set('X-Pin', pin);
      }
      final response = await request.close();

      if (response.statusCode == 200) {
        final body = await response.transform(utf8.decoder).join();
        final data = jsonDecode(body) as Map<String, dynamic>;

        _remoteStatus = data;
        _isConnectedRemote = true;
        _isConnectingRemote = false;

        await _fetchRemoteFiles(cleanUrl);

        // Start polling remote files every 3 seconds
        _remotePollTimer?.cancel();
        _remotePollTimer = Timer.periodic(const Duration(seconds: 3), (_) {
          if (mounted && _isConnectedRemote) {
            _fetchRemoteFiles(cleanUrl);
          }
        });

      } else {
        setState(() {
          _isConnectingRemote = false;
          _remoteError = 'Bağlantı hatası: Sunucu ${response.statusCode} yanıtı verdi.';
        });
      }
    } catch (e) {
      setState(() {
        _isConnectingRemote = false;
        _remoteError = 'Karşı kasaya ulaşılamadı: $e';
      });
    }
  }

  Future<void> _fetchRemoteFiles(String baseUrl) async {
    try {
      final pin = _remotePinController.text.trim();
      final client = HttpClient()..connectionTimeout = const Duration(seconds: 4);
      final req = await client.getUrl(Uri.parse('$baseUrl/api/files'));
      if (pin.isNotEmpty) {
        req.headers.set('X-Vault-PIN', pin);
        req.headers.set('X-Pin', pin);
      }
      final res = await req.close();
      if (res.statusCode == 200) {
        final body = await res.transform(utf8.decoder).join();
        final list = (jsonDecode(body) as List).cast<Map<String, dynamic>>();
        if (mounted) setState(() => _remoteFiles = list);
      }
    } catch (_) {}
  }

  Future<void> _downloadRemoteFile(Map<String, dynamic> f) async {
    final host = _remoteHostController.text.trim();
    final cleanUrl = host.startsWith('http') ? host : 'http://$host';
    final pin = _remotePinController.text.trim();

    try {
      final client = HttpClient();
      final req = await client.getUrl(Uri.parse('$cleanUrl/api/download/${f['id']}'));
      if (pin.isNotEmpty) {
        req.headers.set('X-Vault-PIN', pin);
        req.headers.set('X-Pin', pin);
      }
      final res = await req.close();

      if (res.statusCode == 200) {
        final isEncrypted = res.headers.value('x-encrypted') == '1';
        final ivHex = res.headers.value('x-iv');
        final saltHex = res.headers.value('x-salt') ?? _remoteStatus?['salt'];

        final bytesBuilder = BytesBuilder(copy: false);
        await for (final chunk in res) {
          bytesBuilder.add(chunk);
        }
        var fileBytes = bytesBuilder.toBytes();

        // Decrypt if E2EE
        if (isEncrypted) {
          if (pin.isEmpty) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('❌ Bu dosyanın şifresini çözmek için karşı kasanın PIN kodunu girin!'),
                  backgroundColor: Color(0xFFFF3366),
                ),
              );
            }
            return;
          }

          try {
            fileBytes = VaultCrypto.decryptBytes(
              cipherBytes: fileBytes,
              pin: pin,
              saltHex: saltHex ?? '0102030405060708090a0b0c0d0e0f10',
              ivHex: ivHex ?? '',
            );
          } catch (decErr) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('❌ Şifre Çözülemedi: Hatalı PIN! ($decErr)'),
                  backgroundColor: const Color(0xFFFF3366),
                ),
              );
            }
            return;
          }
        }

        final savedUri = await FilePicker.saveFile(
          dialogTitle: 'Karşı Kasadan Dosya İndir',
          fileName: f['name'],
          bytes: fileBytes,
        );

        if (savedUri != null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('✓ "${f['name']}" karşı kasadan çekildi, çözüldü ve diske kaydedildi!'),
                backgroundColor: const Color(0xFF00FF9D),
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('İndirme hatası: $e'), backgroundColor: const Color(0xFFFF3366)),
        );
      }
    }
  }

  Future<void> _sendLocalFileToRemote() async {
    final host = _remoteHostController.text.trim();
    final cleanUrl = host.startsWith('http') ? host : 'http://$host';
    final pin = _remotePinController.text.trim();

    try {
      final files = await FilePicker.pickFiles();
      if (files.isEmpty) return;

      int successCount = 0;
      final totalFiles = files.length;
      final salt = _remoteStatus?['salt'] ?? '0102030405060708090a0b0c0d0e0f10';

      for (int i = 0; i < totalFiles; i++) {
        final picked = files[i];
        final rawBytes = await picked.xFile.readAsBytes();
        if (rawBytes.isEmpty) continue;

        final iv = VaultCrypto.generateIvHex();

        // Encrypt with remote vault's PIN & Salt
        final cipherBytes = VaultCrypto.encryptBytes(
          plainBytes: rawBytes,
          pin: pin,
          saltHex: salt,
          ivHex: iv,
        );

        final client = HttpClient();
        final req = await client.postUrl(Uri.parse('$cleanUrl/api/upload'));
        req.headers.set('X-Filename', Uri.encodeComponent(picked.name));
        req.headers.set('X-MimeType', 'application/octet-stream');
        req.headers.set('X-Encrypted', '1');
        req.headers.set('X-IV', iv);
        req.headers.set('X-Salt', salt);
        req.headers.set('X-Client-Device', 'GhostVault Masaüstü P2P Köprü');
        if (pin.isNotEmpty) {
          req.headers.set('X-Vault-PIN', pin);
          req.headers.set('X-Pin', pin);
        }

        req.add(cipherBytes);
        final res = await req.close();

        if (res.statusCode >= 200 && res.statusCode < 300) {
          successCount++;
        }
      }

      if (mounted) {
        if (successCount > 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                successCount == 1
                    ? '✓ "${files.first.name}" karşı kasanın RAM\'ine E2EE ile fırlatıldı!'
                    : '✓ $successCount dosya grup halinde karşı kasanın RAM\'ine E2EE ile fırlatıldı!',
              ),
              backgroundColor: const Color(0xFF00FF9D),
              behavior: SnackBarBehavior.floating,
            ),
          );
          await _fetchRemoteFiles(cleanUrl);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Dosyalar gönderilemedi!'),
              backgroundColor: Color(0xFFFF3366),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Aktarım hatası: $e'),
            backgroundColor: const Color(0xFFFF3366),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeUrl = _useTunnelQr && server.tunnelService.isTunnelActive
        ? (server.tunnelService.tunnelUrl ?? server.accessUrl)
        : server.accessUrl;

    final qrUrlWithPin = '$activeUrl/#pin=${server.pin}';

    return Scaffold(
      body: Stack(
        children: [
          // Ambient Glow Orbs
          Positioned(
            top: -120,
            left: -120,
            child: Container(
              width: 450,
              height: 450,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF00F0FF).withValues(alpha: 0.12),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -150,
            right: -150,
            child: Container(
              width: 500,
              height: 500,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF8B5CF6).withValues(alpha: 0.12),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // APP HEADER
                _buildHeader(),

                // NAVIGATION TAB BAR
                _buildNavigationBar(),

                // MAIN CONTENT AREA
                Expanded(
                  child: _selectedTab == 0
                      ? _buildHostVaultTab(activeUrl, qrUrlWithPin)
                      : _buildRemotePeerTab(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF0B1226).withValues(alpha: 0.8),
        border: Border(bottom: BorderSide(color: const Color(0xFF00F0FF).withValues(alpha: 0.2))),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF00F0FF), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF00F0FF).withValues(alpha: 0.4),
                  blurRadius: 16,
                )
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                'assets/logo.png',
                fit: BoxFit.cover,
                errorBuilder: (ctx, err, stack) => const Icon(Icons.shield_rounded, color: Color(0xFF00F0FF)),
              ),
            ),
          ),
          const SizedBox(width: 14),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'GHOST VAULT',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                  color: Colors.white,
                ),
              ),
              Text(
                'Sıfır-Bilgi Askeri E2EE • RAM-Only Ephemeral Safe',
                style: TextStyle(fontSize: 11, color: Color(0xFF8B949E), letterSpacing: 0.5),
              ),
            ],
          ),
          const Spacer(),
          // Panic Button
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF3366),
              foregroundColor: Colors.white,
              elevation: 6,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            ),
            icon: const Icon(Icons.dangerous_rounded, size: 20),
            label: const Text('🔥 PANIC: TÜM RAM\'İ İMHA ET', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            onPressed: () {
              memory.panicWipe();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('🔥 Tüm RAM kriptografik olarak sıfırlandı ve imha edildi!'),
                  backgroundColor: Color(0xFFFF3366),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF10172A).withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF00F0FF).withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: () => setState(() => _selectedTab = 0),
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _selectedTab == 0 ? const Color(0xFF00F0FF).withValues(alpha: 0.2) : Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                  border: Border(
                    bottom: BorderSide(
                      color: _selectedTab == 0 ? const Color(0xFF00F0FF) : Colors.transparent,
                      width: 3,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.shield_rounded, color: _selectedTab == 0 ? const Color(0xFF00F0FF) : Colors.grey, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      '🛡️ KASA SUNUCUM (Yerel & Tünel)',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: _selectedTab == 0 ? const Color(0xFF00F0FF) : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: InkWell(
              onTap: () => setState(() => _selectedTab = 1),
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _selectedTab == 1 ? const Color(0xFF00FF9D).withValues(alpha: 0.2) : Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                  border: Border(
                    bottom: BorderSide(
                      color: _selectedTab == 1 ? const Color(0xFF00FF9D) : Colors.transparent,
                      width: 3,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.hub_rounded, color: _selectedTab == 1 ? const Color(0xFF00FF9D) : Colors.grey, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      '🔗 UZAK KASAYA BAĞLAN (P2P Masaüstü)',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: _selectedTab == 1 ? const Color(0xFF00FF9D) : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- TAB 1: KASA SUNUCUM ---
  Widget _buildHostVaultTab(String activeUrl, String qrUrlWithPin) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left Column: Connections & E2EE Info
          SizedBox(
            width: 380,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildConnectionCard(activeUrl, qrUrlWithPin),
                  const SizedBox(height: 12),
                  _buildTunnelControlCard(),
                  const SizedBox(height: 12),
                  _buildCryptoShieldCard(),
                ],
              ),
            ),
          ),

          const SizedBox(width: 20),

          // Right Column: RAM Files & Actions
          Expanded(
            child: Column(
              children: [
                _buildRamStatsCard(),
                const SizedBox(height: 16),
                Expanded(child: _buildFilesList()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectionCard(String activeUrl, String qrUrlWithPin) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.qr_code_scanner_rounded, color: Color(0xFF00F0FF), size: 20),
                const SizedBox(width: 8),
                const Text('Bağlantı & QR Kod', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                const Spacer(),
                TextButton.icon(
                  style: TextButton.styleFrom(padding: EdgeInsets.zero),
                  icon: const Icon(Icons.tune_rounded, size: 16, color: Color(0xFF00FF9D)),
                  label: const Text('Ağ Değiştir', style: TextStyle(fontSize: 12, color: Color(0xFF00FF9D))),
                  onPressed: _showAdapterPicker,
                ),
              ],
            ),
            const SizedBox(height: 12),

            // QR Code Container
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: const Color(0xFF00F0FF).withValues(alpha: 0.35), blurRadius: 18),
                ],
              ),
              child: QrImageView(
                data: qrUrlWithPin,
                version: QrVersions.auto,
                size: 160,
                backgroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 12),

            // PIN Display
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF080B11),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF00FF9D).withValues(alpha: 0.4)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('KASA PIN: ', style: TextStyle(color: Color(0xFF8B949E), fontSize: 13, fontWeight: FontWeight.bold)),
                  Text(
                    server.pin,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF00FF9D),
                      letterSpacing: 4,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.refresh_rounded, size: 18, color: Color(0xFF00F0FF)),
                    tooltip: 'Yeni PIN ve Salt Üret',
                    onPressed: () => server.regeneratePin(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // URL Copy Row
            InkWell(
              onTap: () => _copyToClipboard(qrUrlWithPin, 'PIN\'li Bağlantı'),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF080B11),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF00F0FF).withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.link_rounded, size: 16, color: Color(0xFF00F0FF)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        activeUrl,
                        style: const TextStyle(fontFamily: 'monospace', fontSize: 12, color: Color(0xFF00F0FF)),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Icon(Icons.copy_rounded, size: 14, color: Colors.grey),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Apple / Mac Bonjour URL
            InkWell(
              onTap: () => _copyToClipboard(server.mdnsUrl, 'Mac / Apple Bonjour Linki'),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF080B11),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFC084FC).withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.apple_rounded, size: 16, color: Color(0xFFC084FC)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Mac: ${server.mdnsUrl}',
                        style: const TextStyle(fontFamily: 'monospace', fontSize: 12, color: Color(0xFFC084FC)),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Text('Sıfır IP', style: TextStyle(fontSize: 10, color: Colors.grey)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTunnelControlCard() {
    final t = server.tunnelService;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.public_rounded, color: Color(0xFF8B5CF6), size: 20),
                const SizedBox(width: 8),
                const Text('Farklı Ağlar İçin Sıfır Port Tüneli', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const Spacer(),
                Switch(
                  value: t.isTunnelActive,
                  activeThumbColor: const Color(0xFF8B5CF6),
                  onChanged: (val) async {
                    if (val) {
                      await t.startTunnel(server.port);
                    } else {
                      await t.stopTunnel();
                    }
                  },
                ),
              ],
            ),
            Text(
              t.isTunnelActive
                  ? '🌍 Dünyaya Açık Tünel Aktif (E2EE Korumalı: Tünel dahi veriyi göremez)'
                  : 'Farklı şehirdeki veya ağdaki biriyle paylaşmak için tüneli açın. Port yönlendirme gerekmez.',
              style: const TextStyle(fontSize: 11, color: Color(0xFF8B949E)),
            ),
            if (t.isStarting) ...[
              const SizedBox(height: 8),
              const Row(
                children: [
                  SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF8B5CF6))),
                  SizedBox(width: 8),
                  Text('Güvenli tünel oluşturuluyor...', style: TextStyle(fontSize: 11, color: Color(0xFF8B5CF6))),
                ],
              ),
            ],
            if (t.isTunnelActive && t.tunnelUrl != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF080B11),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF8B5CF6).withValues(alpha: 0.4)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        t.tunnelUrl!,
                        style: const TextStyle(fontFamily: 'monospace', fontSize: 11, color: Color(0xFFC084FC)),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy_rounded, size: 14, color: Colors.grey),
                      onPressed: () => _copyToClipboard('${t.tunnelUrl}/#pin=${server.pin}', 'Tünel Linki'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Checkbox(
                    value: _useTunnelQr,
                    activeColor: const Color(0xFF8B5CF6),
                    onChanged: (val) => setState(() => _useTunnelQr = val ?? false),
                  ),
                  const Text('QR Kodda Tünel Linkini Göster', style: TextStyle(fontSize: 11)),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCryptoShieldCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.security_rounded, color: Color(0xFF00FF9D), size: 18),
                SizedBox(width: 8),
                Text('Sıfır-Bilgi Askeri E2EE Kalkanı', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF00FF9D))),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              'Dosyalar ağa çıkmadan önce istemcide şifrelenir. Ağı dinleyen biri (Wi-Fi, ISP, Tünel) sadece anlamsız gürültü görür.',
              style: TextStyle(fontSize: 11, color: Color(0xFF8B949E)),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text('Kripto Motoru: ', style: TextStyle(fontSize: 11, color: Colors.grey)),
                const Text('AES-256-CBC • PBKDF2', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
                const Spacer(),
                Text('Salt: ${server.saltHex.substring(0, 8)}...', style: const TextStyle(fontSize: 10, fontFamily: 'monospace', color: Color(0xFF00F0FF))),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRamStatsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('RAM\'DEKİ AKTİF DOSYALAR', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF8B949E))),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      '${memory.totalFiles} Adet',
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF00F0FF)),
                    ),
                    const SizedBox(width: 14),
                    Text(
                      '(${memory.formattedMemoryUsage})',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF00FF9D)),
                    ),
                  ],
                ),
              ],
            ),
            const Spacer(),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00F0FF),
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              icon: const Icon(Icons.file_upload_rounded, size: 18),
              label: const Text('Dosya / Grup Yükle', style: TextStyle(fontWeight: FontWeight.bold)),
              onPressed: _pickAndAddFile,
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10172A),
                foregroundColor: const Color(0xFF00FF9D),
                side: const BorderSide(color: Color(0xFF00FF9D), width: 1.2),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              icon: const Icon(Icons.edit_note_rounded, size: 18),
              label: const Text('Gizli Not', style: TextStyle(fontWeight: FontWeight.bold)),
              onPressed: _showAddNoteDialog,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilesList() {
    if (memory.items.isEmpty) {
      return Card(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_rounded, size: 48, color: Color(0xFF8B949E)),
              const SizedBox(height: 12),
              const Text('Kasa şu an tamamen boş', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              const Text(
                'Telefondan QR kod okutarak veya yukarıdaki butonlarla dosya yükleyebilirsiniz.',
                style: TextStyle(fontSize: 12, color: Color(0xFF8B949E)),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: memory.items.length,
        separatorBuilder: (ctx, i) => const Divider(color: Color(0xFF1E293B)),
        itemBuilder: (ctx, i) {
          final item = memory.items[i];
          final meta = _getFileMeta(item.name, item.mimeType);

          return ListTile(
            leading: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: meta.color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: meta.color.withValues(alpha: 0.4)),
              ),
              child: Icon(meta.icon, color: meta.color),
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: meta.color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: meta.color.withValues(alpha: 0.4)),
                  ),
                  child: Text(meta.badge, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: meta.color)),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    item.name,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            subtitle: Row(
              children: [
                Text('📦 ${item.formattedSize}', style: const TextStyle(fontSize: 12, color: Color(0xFF8B949E))),
                const SizedBox(width: 8),
                Text('• ${item.senderInfo ?? "Web"}', style: const TextStyle(fontSize: 12, color: Color(0xFF8B949E))),
                if (item.isEncrypted) ...[
                  const SizedBox(width: 8),
                  const Text('• 🔒 E2EE Şifreli', style: TextStyle(fontSize: 12, color: Color(0xFF00FF9D))),
                ],
                if (item.maxDownloads == 1) ...[
                  const SizedBox(width: 8),
                  const Text('• 🔥 Tek Okumalık', style: TextStyle(fontSize: 12, color: Color(0xFFFF3366))),
                ],
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.download_rounded, color: Color(0xFF00F0FF)),
                  tooltip: 'Diske Çöz ve Kaydet',
                  onPressed: () => _saveFileToDisk(item),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_forever_rounded, color: Color(0xFFFF3366)),
                  tooltip: 'RAM\'den İmha Et',
                  onPressed: () => memory.shredItem(item.id),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // --- TAB 2: UZAK KASAYA BAĞLAN (P2P DESKTOP BRIDGE) ---
  Widget _buildRemotePeerTab() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Column(
        children: [
          // Remote Connection Form Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.cable_rounded, color: Color(0xFF00FF9D)),
                      SizedBox(width: 8),
                      Text('Uzak Bilgisayar Kasasına Bağlan (Mac & Windows P2P)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Başka bir bilgisayarda GhostVault çalışıyorsa, IP adresi / mDNS / Tünel linki ve PIN ile doğrudan RAM\'den RAM\'e bağlanın.',
                    style: TextStyle(fontSize: 12, color: Color(0xFF8B949E)),
                  ),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: TextField(
                          controller: _remoteHostController,
                          style: const TextStyle(color: Colors.white, fontFamily: 'monospace'),
                          decoration: InputDecoration(
                            labelText: 'Hedef IP / mDNS / Tünel URL',
                            hintText: 'Örn: 192.168.1.45:7788 veya macbook.local:7788 veya https://...lhr.life',
                            prefixIcon: const Icon(Icons.dns_rounded, color: Color(0xFF00F0FF)),
                            filled: true,
                            fillColor: const Color(0xFF080B11),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        flex: 2,
                        child: TextField(
                          controller: _remotePinController,
                          style: const TextStyle(color: Color(0xFF00FF9D), fontFamily: 'monospace', fontWeight: FontWeight.bold, letterSpacing: 2),
                          decoration: InputDecoration(
                            labelText: 'Hedef Kasa PIN\'i',
                            hintText: '6 haneli PIN',
                            prefixIcon: const Icon(Icons.pin_rounded, color: Color(0xFF00FF9D)),
                            filled: true,
                            fillColor: const Color(0xFF080B11),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isConnectedRemote ? const Color(0xFF00FF9D) : const Color(0xFF00F0FF),
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: _isConnectingRemote
                            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                            : Icon(_isConnectedRemote ? Icons.refresh_rounded : Icons.login_rounded),
                        label: Text(
                          _isConnectedRemote ? 'Yenile ⚡' : 'Kasaya Bağlan ⚡',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        onPressed: _isConnectingRemote ? null : _connectToRemoteVault,
                      ),
                    ],
                  ),

                  if (_remoteError != null) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF3366).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFFF3366).withValues(alpha: 0.4)),
                      ),
                      child: Text('❌ $_remoteError', style: const TextStyle(color: Color(0xFFFF3366), fontSize: 12)),
                    ),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: 14),

          // Remote Files View
          Expanded(
            child: Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    child: Row(
                      children: [
                        const Icon(Icons.folder_shared_rounded, color: Color(0xFF00F0FF)),
                        const SizedBox(width: 8),
                        Text(
                          _isConnectedRemote
                              ? 'Uzak Kasadaki Aktif Dosyalar (${_remoteFiles.length} Adet)'
                              : 'Uzak Kasa Dosyaları (Henüz Bağlanılmadı)',
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                        const Spacer(),
                        if (_isConnectedRemote)
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF00FF9D),
                              foregroundColor: Colors.black,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            icon: const Icon(Icons.upload_file_rounded, size: 18),
                            label: const Text('Dosya / Grup Gönder', style: TextStyle(fontWeight: FontWeight.bold)),
                            onPressed: _sendLocalFileToRemote,
                          ),
                      ],
                    ),
                  ),
                  const Divider(color: Color(0xFF1E293B), height: 1),
                  Expanded(
                    child: !_isConnectedRemote
                        ? const Center(
                            child: Text(
                              'Hedef kasanın adresini ve PIN\'ini girip "Kasaya Bağlan" butonuna basın.',
                              style: TextStyle(color: Color(0xFF8B949E)),
                            ),
                          )
                        : _remoteFiles.isEmpty
                            ? const Center(
                                child: Text('Karşı kasa şu anda boş.', style: TextStyle(color: Color(0xFF8B949E))),
                              )
                            : ListView.separated(
                                padding: const EdgeInsets.all(12),
                                itemCount: _remoteFiles.length,
                                separatorBuilder: (ctx, i) => const Divider(color: Color(0xFF1E293B)),
                                itemBuilder: (ctx, i) {
                                  final f = _remoteFiles[i];
                                  final meta = _getFileMeta(f['name'], f['mimeType'] ?? '');
                                  final isEncrypted = f['isEncrypted'] == true;

                                  return ListTile(
                                    leading: Container(
                                      width: 42,
                                      height: 42,
                                      decoration: BoxDecoration(
                                        color: meta.color.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Icon(meta.icon, color: meta.color),
                                    ),
                                    title: Text(f['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                                    subtitle: Text(
                                      '📦 ${(f['sizeBytes'] / 1024).toStringAsFixed(1)} KB • ${isEncrypted ? "🔒 E2EE Şifreli" : "Açık"}',
                                      style: const TextStyle(fontSize: 12, color: Color(0xFF8B949E)),
                                    ),
                                    trailing: ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF00F0FF),
                                        foregroundColor: Colors.black,
                                      ),
                                      icon: const Icon(Icons.download_rounded, size: 16),
                                      label: const Text('İndir & Çöz', style: TextStyle(fontWeight: FontWeight.bold)),
                                      onPressed: () => _downloadRemoteFile(f),
                                    ),
                                  );
                                },
                              ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
