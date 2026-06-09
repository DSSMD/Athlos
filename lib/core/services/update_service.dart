import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../presentation/widgets/shared/update_dialog.dart';

class UpdateService {
  static const String _githubReleaseUrl =
      'https://api.github.com/repos/DSSMD/Athlos/releases/latest';
  static const String _lastCheckPrefKey = 'last_update_check_timestamp';
  
  // Evitar múltiples peticiones simultáneas
  static bool _isChecking = false;

  /// Realiza la comprobación de actualizaciones.
  /// [forceShow] se establece en true cuando el usuario busca actualizaciones manualmente.
  static Future<void> checkForUpdates(BuildContext context, {bool forceShow = false}) async {
    if (_isChecking) return;
    _isChecking = true;

    try {
      // Si no es manual, limitar a un chequeo cada 24 horas para evitar exceder el límite de la API de GitHub
      if (!forceShow) {
        final prefs = await SharedPreferences.getInstance();
        final lastCheck = prefs.getInt(_lastCheckPrefKey) ?? 0;
        final now = DateTime.now().millisecondsSinceEpoch;
        
        // 24 horas = 24 * 60 * 60 * 1000 = 86,400,000 ms
        if (now - lastCheck < 86400000) {
          _isChecking = false;
          return;
        }
        await prefs.setInt(_lastCheckPrefKey, now);
      }

      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;

      final response = await http.get(
        Uri.parse(_githubReleaseUrl),
        headers: {
          'Accept': 'application/vnd.github.v3+json',
          'User-Agent': 'Athlos-App-Client',
        },
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final latestVersion = data['tag_name'] as String? ?? '';
        final releaseNotes = data['body'] as String? ?? 'Sin notas de versión disponibles.';
        final releaseHtmlUrl = data['html_url'] as String? ?? 'https://github.com/DSSMD/Athlos/releases';

        if (latestVersion.isNotEmpty && _isNewerVersion(currentVersion, latestVersion)) {
          // Identificar el asset adecuado según plataforma
          String downloadUrl = releaseHtmlUrl; // Fallback a la web de release
          final assets = data['assets'] as List<dynamic>?;
          
          if (assets != null && assets.isNotEmpty) {
            if (kIsWeb) {
              // Web no maneja APK ni EXE directamente
            } else if (Platform.isWindows) {
              final exeAsset = assets.firstWhere(
                (asset) => (asset['name'] as String).toLowerCase().endsWith('.exe'),
                orElse: () => null,
              );
              if (exeAsset != null) {
                downloadUrl = exeAsset['browser_download_url'] as String;
              }
            } else if (Platform.isAndroid) {
              final apkAsset = assets.firstWhere(
                (asset) => (asset['name'] as String).toLowerCase().endsWith('.apk'),
                orElse: () => null,
              );
              if (apkAsset != null) {
                downloadUrl = apkAsset['browser_download_url'] as String;
              }
            }
          }

          if (context.mounted) {
            showDialog(
              context: context,
              barrierDismissible: true,
              builder: (context) => UpdateDialog(
                currentVersion: currentVersion,
                latestVersion: latestVersion,
                releaseNotes: releaseNotes,
                downloadUrl: downloadUrl,
              ),
            );
          }
        } else {
          if (forceShow && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Athlos está actualizado. Versión actual: v${packageInfo.version}'),
                backgroundColor: Colors.green,
              ),
            );
          }
        }
      } else {
        if (forceShow && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('No se pudo verificar la actualización (Código ${response.statusCode})'),
              backgroundColor: const Color(0xFFFF0000),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error comprobando actualizaciones: $e');
      if (forceShow && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error de conexión al buscar actualizaciones.'),
            backgroundColor: Color(0xFFFF0000),
          ),
        );
      }
    } finally {
      _isChecking = false;
    }
  }

  /// Compara si la versión [latest] es más reciente que [current] siguiendo la especificación semántica.
  static bool _isNewerVersion(String current, String latest) {
    // Limpiar caracteres no numéricos excepto los puntos
    String cleanCurrent = current.replaceAll(RegExp(r'[a-zA-Z]'), '').trim();
    String cleanLatest = latest.replaceAll(RegExp(r'[a-zA-Z]'), '').trim();

    // Eliminar posibles sufijos de builds o prereleases (+ o -)
    cleanCurrent = cleanCurrent.split('+')[0].split('-')[0];
    cleanLatest = cleanLatest.split('+')[0].split('-')[0];

    final curParts = cleanCurrent.split('.');
    final latParts = cleanLatest.split('.');

    final maxLength = curParts.length > latParts.length ? curParts.length : latParts.length;

    for (int i = 0; i < maxLength; i++) {
      final curNum = i < curParts.length ? (int.tryParse(curParts[i]) ?? 0) : 0;
      final latNum = i < latParts.length ? (int.tryParse(latParts[i]) ?? 0) : 0;

      if (latNum > curNum) return true;
      if (curNum > latNum) return false;
    }

    return false;
  }
}
