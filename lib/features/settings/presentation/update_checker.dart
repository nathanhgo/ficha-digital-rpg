import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/theme.dart';

class UpdateChecker {
  static const String _repoName = 'nathanhgo/ficha-digital-rpg';

  static Future<void> checkForUpdates(BuildContext context) async {
    if (kIsWeb) return; // Na web o app já está sempre na última versão

    try {
      final client = HttpClient();
      final request = await client.getUrl(Uri.parse('https://api.github.com/repos/$_repoName/releases/latest'));
      request.headers.add('User-Agent', 'FichaDigitalRPG-UpdateChecker');
      final response = await request.close();

      if (response.statusCode != 200) return;

      final stringData = await response.transform(utf8.decoder).join();
      final json = jsonDecode(stringData);

      final tagName = json['tag_name'] as String?;
      final releaseNotes = json['body'] as String? ?? '';
      
      if (tagName == null) return;
      
      // Clean up tag name (e.g., 'v1.0.1' -> '1.0.1')
      final latestVersion = tagName.replaceAll('v', '');
      
      // Usamos a página da release (html_url) em vez do link direto do APK.
      // O Android costuma cancelar downloads diretos de APKs via Intent (url_launcher),
      // mas funciona perfeitamente se o usuário clicar no link dentro da própria página do GitHub.
      final downloadUrl = json['html_url'] as String?;

      if (downloadUrl == null || downloadUrl.isEmpty) return;

      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;

      if (_isNewerVersion(currentVersion, latestVersion)) {
        if (!context.mounted) return;
        _showUpdateDialog(context, latestVersion, downloadUrl, releaseNotes);
      }
    } catch (e) {
      debugPrint("Erro ao checar atualizações no GitHub: $e");
    }
  }

  static bool _isNewerVersion(String current, String latest) {
    final v1 = current.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    final v2 = latest.split('.').map((e) => int.tryParse(e) ?? 0).toList();

    for (int i = 0; i < v2.length; i++) {
      final val1 = i < v1.length ? v1[i] : 0;
      final val2 = v2[i];
      if (val2 > val1) return true;
      if (val2 < val1) return false;
    }
    return false;
  }

  static void _showUpdateDialog(BuildContext context, String version, String url, String notes) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AlertDialog(
        backgroundColor: SteampunkTheme.castIron,
        title: Text(
          'NOVA VERSÃO DISPONÍVEL! (v$version)',
          style: const TextStyle(color: SteampunkTheme.copper, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Uma nova atualização do Despertar do Caos está disponível para baixar no GitHub.',
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 16),
            if (notes.isNotEmpty) ...[
              const Text('O que há de novo:', style: TextStyle(color: SteampunkTheme.brassGlow, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              SizedBox(
                height: 100,
                child: SingleChildScrollView(
                  child: Text(notes, style: const TextStyle(color: Colors.white70)),
                ),
              ),
            ]
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('DEPOIS', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            onPressed: () async {
              final uri = Uri.parse(url);
              try {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              } catch (e) {
                debugPrint('Erro ao abrir URL de atualização: $e');
              }
            },
            child: const Text('BAIXAR ATUALIZAÇÃO', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
