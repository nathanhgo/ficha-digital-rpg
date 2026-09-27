import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/theme.dart';

/// Versão semântica (major.minor.patch) + build (versionCode/CFBundleVersion).
///
/// Existe porque a comparação precisa ser feita sobre números, e não sobre
/// strings: a tag do GitHub chega como `v1.0.8`, a versão instalada pode vir
/// com sufixo de build (`1.0.7+6`) e o build number é um campo separado em
/// [PackageInfo]. Comparar isso como texto (ou parsear cada parte com
/// `int.tryParse(...) ?? 0`) gera falso positivo de "nova versão".
class AppVersion implements Comparable<AppVersion> {
  final int major;
  final int minor;
  final int patch;
  final int build;

  const AppVersion(this.major, this.minor, this.patch, [this.build = 0]);

  static final RegExp _versionPattern = RegExp(r'(\d+(?:\.\d+)*)');
  static final RegExp _buildPattern = RegExp(r'\+(\d+)');

  /// Aceita `1.0.7`, `v1.0.7`, `1.0.7+6`, `1.0.7-beta.1`.
  /// [buildOverride] (ex.: `packageInfo.buildNumber`) tem prioridade sobre o
  /// sufixo `+N` escrito no texto.
  static AppVersion parse(String raw, {String? buildOverride}) {
    final text = raw.trim();
    final match = _versionPattern.firstMatch(text);
    final numbers = (match?.group(1) ?? '0')
        .split('.')
        .map((part) => int.tryParse(part) ?? 0)
        .toList();

    final build = int.tryParse(buildOverride?.trim() ?? '') ??
        int.tryParse(_buildPattern.firstMatch(text)?.group(1) ?? '') ??
        0;

    return AppVersion(
      numbers.isNotEmpty ? numbers[0] : 0,
      numbers.length > 1 ? numbers[1] : 0,
      numbers.length > 2 ? numbers[2] : 0,
      build,
    );
  }

  /// `false` quando nada foi reconhecido (versão vazia/ilegível). Nesse caso o
  /// chamador deve preferir o silêncio a arriscar um aviso falso.
  bool get isKnown => major > 0 || minor > 0 || patch > 0 || build > 0;

  @override
  int compareTo(AppVersion other) {
    if (major != other.major) return major.compareTo(other.major);
    if (minor != other.minor) return minor.compareTo(other.minor);
    if (patch != other.patch) return patch.compareTo(other.patch);
    return build.compareTo(other.build);
  }

  bool isNewerThan(AppVersion other) => compareTo(other) > 0;

  @override
  String toString() => '$major.$minor.$patch+$build';
}

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

      // Tag do GitHub -> versão remota (ex.: 'v1.0.8' -> 1.0.8+0).
      final latest = AppVersion.parse(tagName);
      final latestLabel = tagName.replaceFirst(RegExp(r'^[vV]'), '');

      // Usamos a página da release (html_url) em vez do link direto do APK.
      // O Android costuma cancelar downloads diretos de APKs via Intent (url_launcher),
      // mas funciona perfeitamente se o usuário clicar no link dentro da própria página do GitHub.
      final downloadUrl = json['html_url'] as String?;

      if (downloadUrl == null || downloadUrl.isEmpty) return;

      // Versão REAL do build instalado (versionName + versionCode), não a do
      // pubspec. São fontes diferentes e podem divergir se a release for
      // publicada sem bump de `version:` no pubspec.yaml.
      final packageInfo = await PackageInfo.fromPlatform();
      final current = AppVersion.parse(
        packageInfo.version,
        buildOverride: packageInfo.buildNumber,
      );

      // Sem versão local legível não há como comparar com segurança: avisar aqui
      // produziria o falso positivo de sempre ("nova versão" em todo boot).
      if (!current.isKnown) return;

      if (latest.isNewerThan(current)) {
        if (!context.mounted) return;
        _showUpdateDialog(context, latestLabel, downloadUrl, releaseNotes);
      }
    } catch (e) {
      debugPrint("Erro ao checar atualizações no GitHub: $e");
    }
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
